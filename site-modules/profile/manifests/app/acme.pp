# @summary Manages acme.sh installation and certificate issuance via DNS-01 (Cloudflare)
#
# Installs acme.sh, configures Cloudflare credentials via BWS, and issues/renews
# wildcard certificates. Deploy hooks notify dependent services on renewal.
#
# @param version
#   acme.sh release version.
#   renovate: datasource=github-releases depName=acmesh-official/acme.sh extractVersion=^(?<version>.+)$
# @param config_home
#   Directory for acme.sh account data and renewal state.
# @param cert_base
#   Base directory for issued certificates. Per-domain subdirectories are created here.
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
  Stdlib::Absolutepath $config_home   = '/var/lib/acme',
  Stdlib::Absolutepath $cert_base     = '/etc/acme',
  String               $email         = lookup('profile::acme::email'),
  Array[String]        $domains       = [],
  String               $cf_token_uuid = '8565e45d-d1a5-4eec-a4ae-b35d00b79b05',
  String               $bws_token     = lookup('secrets::kopia::bws_token'),
  Hash[String, String] $deploy_hooks  = {},
) {
  include profile::app::tools::bws

  # Install acme.sh from tarball
  profile::app::binary_install { 'acme.sh':
    version     => $version,
    binary      => 'acme.sh',
    url         => "https://github.com/acmesh-official/acme.sh/archive/refs/tags/${version}.tar.gz",
    tarball     => true,
    tar_extract => "acme.sh-${version}/acme.sh",
    version_cmd => '/usr/local/bin/acme.sh --version 2>&1 | grep -oP "(?<=v)[\d.]+"',
    install_dir => '/usr/local/bin',
  }

  # acme.sh config/state home
  file { $config_home:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  # Base directory for deployed certs
  file { $cert_base:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
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

      exec /usr/local/bin/acme.sh --config-home "${config_home}" "\$@"
      | SCRIPT
    require => Profile::App::Binary_install['acme.sh'],
  }

  # Per-domain cert issuance
  $domains.each |String $domain| {
    $cert_dir = "${cert_base}/${domain}"

    file { $cert_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      require => File[$cert_base],
    }

    # Build reload command from deploy_hooks
    $reload_cmd = $deploy_hooks.map |String $label, String $unit| {
      "systemctl restart ${unit}"
    }.join(' && ')

    $reloadcmd_flag = $reload_cmd ? {
      ''      => '',
      default => "--reloadcmd '${reload_cmd}'",
    }

    # Issue cert — skipped if fullchain already exists
    exec { "acme-issue-${domain}":
      command => @("CMD"/L$),
        /usr/local/bin/acme-issue \
          --issue \
          --dns dns_cf \
          --domain "${domain}" \
          --server letsencrypt \
          --accountemail "${email}" \
          --install-cert \
          --cert-file "${cert_dir}/cert.pem" \
          --key-file "${cert_dir}/private.key" \
          --fullchain-file "${cert_dir}/fullchain.pem" \
          ${reloadcmd_flag}
        | CMD
      creates => "${cert_dir}/fullchain.pem",
      path    => ['/usr/bin', '/bin', '/usr/local/bin'],
      require => [
        File['/usr/local/bin/acme-issue'],
        File[$cert_dir],
      ],
    }

    # Renewal via systemd timer
    systemd::unit_file { "acme-renew-${domain}.service":
      enable  => false,
      active  => false,
      content => @("SERVICE"/L$),
        [Unit]
        Description=Renew acme.sh certificate for ${domain}
        After=network-online.target
        Wants=network-online.target

        [Service]
        Type=oneshot
        ExecStart=/usr/local/bin/acme-issue --renew --domain ${domain} --server letsencrypt ${reloadcmd_flag}
        | SERVICE
    }

    systemd::unit_file { "acme-renew-${domain}.timer":
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
      require => Systemd::Unit_file["acme-renew-${domain}.service"],
    }
  }
}
