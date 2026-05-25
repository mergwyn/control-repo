# profile/manifests/app/dhcpd/watchdog.pp
class profile::app::dhcpd::watchdog (
  Stdlib::IP::Address $peer_address,
  Integer             $peer_port     = 647,
  Integer             $wait_seconds  = 60,
  String              $leases_file   = '/var/lib/dhcp/dhcpd.leases',
  String              $failover_name = 'dhcp-failover',
) {
  file { '/usr/local/sbin/dhcp-failover-watchdog.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => epp('profile/dhcp-failover-watchdog.sh.epp', {
      peer_address  => $peer_address,
      peer_port     => $peer_port,
      wait_seconds  => $wait_seconds,
      leases_file   => $leases_file,
      failover_name => $failover_name,
    }),
  }

  file { '/usr/local/sbin/dhcp-failover-watchdog-launcher.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => @(EOT),
      #!/usr/bin/env bash
      # Managed by Puppet - do not edit
      exec journalctl -fu isc-dhcp-server --output=cat \
        | grep --line-buffered "communications-interrupted" \
        | while read -r line; do
            /usr/local/sbin/dhcp-failover-watchdog.sh
          done
      | EOT
  }

  systemd::unit_file { 'dhcp-failover-watchdog.service':
    enable  => true,
    active  => true,
    content => @("EOT"/L),
      [Unit]
      Description=DHCP Failover Watchdog
      After=isc-dhcp-server.service

      [Service]
      Type=simple
      ExecStart=/usr/local/sbin/dhcp-failover-watchdog-launcher.sh
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
      | EOT
  }

  File['/usr/local/sbin/dhcp-failover-watchdog.sh']
    ~> Systemd::Unit_file['dhcp-failover-watchdog.service']
  File['/usr/local/sbin/dhcp-failover-watchdog-launcher.sh']
    ~> Systemd::Unit_file['dhcp-failover-watchdog.service']
}
