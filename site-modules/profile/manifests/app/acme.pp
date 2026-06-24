# @summary Manages acme.sh installation and certificate issuance via DNS-01 (Cloudflare)
#
# Installs acme.sh using its own native installer (placing everything under
# /root/.acme.sh/, including dnsapi/, account data, and renewal state — fighting
# this layout causes installer failures). Configures Cloudflare credentials via
# BWS and issues/renews wildcard certificates. On renewal, all scripts in
# deploy.d/ are executed. Other profiles drop scripts into that directory to hook
# into the renewal process without coupling back to this profile.
#
# @param version
#   acme.sh release version.
#   renovate: datasource=github-releases depName=acmesh-official/acme.sh extractVersion=^(?<version>.+)$
# @param cert_base
#   Base directory for deployed certificates. Per-domain subdirectories are created here.
# @param email
#   Email address for Let's Encrypt account registration.
# @param domains
#   List of domains to issue certificates for.
# @param cf_token_uuid
#   BWS secret UUID for the Cloudflare API token.
# @param bws_token
#   BWS access token, sourced from eyaml.
# @param deploy_hooks
#   Hash of arbitrary label to systemd unit name. All units are restarted on cert renewal.
class profile::app::acme (
  String               $version       = '3.1.0', #renovate: datasource=github-releases depName=acmesh-official/acme.sh extractVersion=^(?<version>.+)$
  Stdlib::Absolutepath $cert_base     = '/etc/acme',
  String               $email         = lookup('profile::app::acme::email'),
  Array[String]        $domains       = [],
  String               $cf_token_uuid = '8565e45d-d1a5-4eec-a4ae-b35d00b79b05',
  String               $bws_token     = lookup('secrets::kopia::bws_token'),
  Hash[String, String] $deploy_hooks  = {},
) {
  include profile::app::tools::bws

  $acme_bin = '/root/.acme.sh/acme.sh'

  # Download tarball and run acme.sh's own installer from within it.
  # acme.sh expects to run from its own extracted directory and installs
  # itself, dnsapi/, and account state under --home (defaults to ~/.acme.sh).
  exec { 'acme.sh-install':
    command => @("CMD"/L),
      set -e
      rm -rf /tmp/acme.sh-install
      mkdir -p /tmp/acme.sh-install
      curl -fsSL https://github.com/acmesh-official/acme.sh/archive/refs/tags/${version}.tar.gz -o /tmp/acme.sh-install/acme.sh.tar.gz
      tar -xzf /tmp/acme.sh-install/acme.sh.tar.gz -C /tmp/acme.sh-install --strip-components=1
      cd /tmp/acme.sh-install
      ./acme.sh --install --no-cron
      rm -rf /tmp/acme.sh-install
      | CMD
    path    => ['/usr/bin', '/bin', '/usr/local/bin'],
    creates => $acme_bin,
    require => Package['curl'],
  }

  # Base directory for deployed certs
  file { $cert_base:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # deploy.d directory — scripts dropped here are run on every cert renewal
  file { "${cert_base}/deploy.d":
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    require => File[$cert_base],
  }

  # deploy.d runner — executes all scripts in deploy.d in order
  file { '/usr/local/bin/acme-deploy':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => @("SCRIPT"/L$),
      #!/usr/bin/env bash
      set -euo pipefail

      DEPLOY_DIR="${cert_base}/deploy.d"

      if [[ ! -d "\${DEPLOY_DIR}" ]]; then
        echo "Deploy directory \${DEPLOY_DIR} not found"
        exit 1
      fi

      for script in "\${DEPLOY_DIR}"/[0-9]*.sh; do
        [[ -x "\$script" ]] || continue
        echo "Running deploy script: \$script"
        "\$script" || { echo "Deploy script failed: \$script"; exit 1; }
      done
      | SCRIPT
    require => File["${cert_base}/deploy.d"],
  }

  # Wrapper script: fetches CF token from BWS and invokes acme.sh
  # CF_Token is the variable name acme.sh expects for dns_cf
  file { '/usr/local/bin/acme-issue':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => @("SCRIPT"/L$),
      #!/usr/bin/env bash
      set -euo pipefail

      BWS_ACCESS_TOKEN="${bws_token}"
      export BWS_ACCESS_TOKEN

      CF_Token=\$(bws secret get "${cf_token_uuid}" --output json | jq -r '.value')
      [[ -z "\${CF_Token}" ]] && { echo "Failed to retrieve Cloudflare token from BWS"; exit 1; }
      export CF_Token

      exec ${acme_bin} "\$@"
      | SCRIPT
    require => Exec['acme.sh-install'],
  }

  # Per-domain cert issuance
  $domains.each |String $domain| {
    # Filesystem-safe name: replace * only (dots are valid in paths)
    $fs_domain = regsubst($domain, '[*]', 'wildcard', 'G')

    # Systemd-safe name: replace * and . with -, prefix wildcard- for readability
    $safe_domain = regsubst(regsubst($domain, '[*\.]', '-', 'G'), '^-+', 'wildcard-')

    $cert_dir = "${cert_base}/${fs_domain}"

    file { $cert_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File[$cert_base],
    }

    # Build reload command: run deploy.d runner, then restart any deploy_hooks units
    $hook_cmds = $deploy_hooks.map |String $label, String $unit| {
      "systemctl restart ${unit}"
    }
    $all_reload_cmds = ['/usr/local/bin/acme-deploy'] + $hook_cmds
    $reload_cmd = $all_reload_cmds.join(' && ')

    # Issue cert — acme.sh stores it under its own --home; skipped if already issued
    exec { "acme-issue-${safe_domain}":
      command => @("CMD"/L$),
        /usr/local/bin/acme-issue \
          --issue \
          --dns dns_cf \
          --domain "${domain}" \
          --server letsencrypt \
          --accountemail "${email}"
        | CMD
      path    => ['/usr/bin', '/bin', '/usr/local/bin'],
      unless  => "test -d /root/.acme.sh/${domain}",
      require => [
        File['/usr/local/bin/acme-issue'],
        File[$cert_dir],
      ],
    }

    # Install cert to target paths — reruns if cert is renewed
    exec { "acme-install-cert-${safe_domain}":
      command => @("CMD"/L$),
        /usr/local/bin/acme-issue \
          --install-cert \
          --domain "${domain}" \
          --cert-file "${cert_dir}/cert.pem" \
          --key-file "${cert_dir}/private.key" \
          --fullchain-file "${cert_dir}/fullchain.pem" \
          --reloadcmd '${reload_cmd}'
        | CMD
      path    => ['/usr/bin', '/bin', '/usr/local/bin'],
      unless  => "test -f ${cert_dir}/fullchain.pem",
      require => Exec["acme-issue-${safe_domain}"],
    }

    # Renewal service (triggered by timer)
    systemd::unit_file { "acme-renew-${safe_domain}.service":
      enable  => false,
      active  => false,
      content => @("SERVICE"/L$),
        [Unit]
        Description=Renew acme.sh certificate for ${domain}
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=oneshot
        ExecStart=/usr/local/bin/acme-issue --renew --domain ${domain} --server letsencrypt
        ExecStartPost=/usr/local/bin/acme-issue --install-cert --domain ${domain} --cert-file ${cert_dir}/cert.pem --key-file ${cert_dir}/private.key --fullchain-file ${cert_dir}/fullchain.pem --reloadcmd '${reload_cmd}'
        | SERVICE
    }

    # Daily renewal timer
    systemd::unit_file { "acme-renew-${safe_domain}.timer":
      enable  => true,
      active  => true,
      content => @("TIMER"/L$),
        [Unit]
        Description=Daily renewal check for ${domain}

        [Timer]
        OnCalendar=daily
        RandomizedDelaySec=1h
        Persistent=true

        [Install]
        WantedBy=timers.target
        | TIMER
      require => Systemd::Unit_file["acme-renew-${safe_domain}.service"],
    }
  }
}
