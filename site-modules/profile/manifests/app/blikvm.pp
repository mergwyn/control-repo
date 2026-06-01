# @summary Deploys TLS certificates to BliKVM via SSH
#
# Drops a deploy script into /etc/acme/deploy.d/ which is executed by
# profile::app::acme on cert renewal. Also installs a systemd service and
# boot timer to ensure certs are deployed after a Delta reboot.
#
# Requires one-time manual SSH key setup — see blikvm_cert_deploy_setup.md.
#
# @param blikvm_host
#   Hostname or IP of the BliKVM device.
# @param blikvm_user
#   SSH user on BliKVM. Defaults to root as all kvmd services run as root.
# @param ssh_key
#   Path to the SSH private key used for deploy authentication.
#   This key must be created manually — see setup documentation.
# @param cert_base
#   Base directory for acme.sh issued certs. Must match profile::app::acme.
# @param domain
#   Domain whose cert is deployed to BliKVM.
# @param blikvm_cert_dir
#   Directory on BliKVM where certs are installed.
# @param boot_delay_sec
#   Seconds to wait after boot before running the deploy. Allows network to settle.
class profile::app::blikvm (
  String               $blikvm_host    = 'blikvm-lan',
  String               $blikvm_user    = 'root',
  Stdlib::Absolutepath $ssh_key        = '/etc/acme/.ssh/blikvm_deploy',
  Stdlib::Absolutepath $cert_base      = '/etc/acme',
  String               $domain         = lookup('profile::app::acme::domains')[0],
  Stdlib::Absolutepath $blikvm_cert_dir = '/etc/kvmd/nginx/ssl',
  Integer              $boot_delay_sec = 300,
) {
  # SSH options used in all remote calls
  $ssh_opts = "-i ${ssh_key} -o BatchMode=yes -o StrictHostKeyChecking=yes"

  # Deploy script — placed in deploy.d so acme-deploy runner picks it up on renewal
  file { "${cert_base}/deploy.d/10-blikvm.sh":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0700',
    content => @("SCRIPT"/L$),
      #!/usr/bin/env bash
      set -euo pipefail

      BLIKVM_HOST="${blikvm_host}"
      BLIKVM_USER="${blikvm_user}"
      SSH_KEY="${ssh_key}"
      SSH_OPTS="${ssh_opts}"
      CERT_SRC="${cert_base}/${domain}/fullchain.pem"
      KEY_SRC="${cert_base}/${domain}/private.key"
      REMOTE_DIR="${blikvm_cert_dir}"

      echo "Deploying certificates to \${BLIKVM_HOST}"

      # Remount filesystem read-write
      ssh \${SSH_OPTS} \${BLIKVM_USER}@\${BLIKVM_HOST} "mount -o remount,rw /"

      # Copy cert and key
      scp -i \${SSH_KEY} -o BatchMode=yes -o StrictHostKeyChecking=yes \
        "\${CERT_SRC}" "\${BLIKVM_USER}@\${BLIKVM_HOST}:\${REMOTE_DIR}/server.crt"
      scp -i \${SSH_KEY} -o BatchMode=yes -o StrictHostKeyChecking=yes \
        "\${KEY_SRC}" "\${BLIKVM_USER}@\${BLIKVM_HOST}:\${REMOTE_DIR}/server.key"

      # Set permissions, test nginx config, restart services, remount read-only
      ssh \${SSH_OPTS} \${BLIKVM_USER}@\${BLIKVM_HOST} bash <<'REMOTE'
        set -e
        chmod 600 /etc/kvmd/nginx/ssl/server.key
        chmod 644 /etc/kvmd/nginx/ssl/server.crt
        nginx -t
        systemctl restart kvmd-web
        systemctl restart kvmd-nginx
        mount -o remount,ro /
      REMOTE

      echo "Certificate deploy to \${BLIKVM_HOST} complete"
      | SCRIPT
    require => File["${cert_base}/deploy.d"],
  }

  # Boot deploy service — runs deploy script after boot
  systemd::unit_file { 'acme-deploy-blikvm.service':
    enable  => false,
    active  => false,
    content => @("SERVICE"/L$),
      [Unit]
      Description=Deploy acme.sh certificates to BliKVM
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=oneshot
      ExecStart=${cert_base}/deploy.d/10-blikvm.sh
      | SERVICE
    require => File["${cert_base}/deploy.d/10-blikvm.sh"],
  }

  # Boot timer — fires once after boot with a short delay for network to settle
  systemd::unit_file { 'acme-deploy-blikvm.timer':
    enable  => true,
    active  => true,
    content => @("TIMER"/L$),
      [Unit]
      Description=Deploy BliKVM certificates shortly after boot

      [Timer]
      OnBootSec=${boot_delay_sec}s
      Unit=acme-deploy-blikvm.service

      [Install]
      WantedBy=timers.target
      | TIMER
    require => Systemd::Unit_file['acme-deploy-blikvm.service'],
  }
}
