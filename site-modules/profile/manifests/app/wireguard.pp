# @summary WireGuard VPN tunnel for egress routing
#
# Runs a WireGuard tunnel in an LXC container, providing a routed egress
# point for pod traffic (via per-pod init container routing) and, longer
# term, for Cilium EgressGatewayPolicy.
#
# The container needs:
#   - NET_ADMIN capability (set in LXC profile)
#   - wireguard kernel module on host (built-in on Ubuntu 24.04)
#
## Wireguard configs
# The manifest assumes the config only contains one Interface and 1 Peer
# and that The Interface section is before the Peer section
#
class profile::app::wireguard (
  String[1] $lan        = $facts['networking']['primary'], # interface facing k8s nodes
  String[1] $vpn        = 'wg0',                           # WireGuard interface name
  String[1] $lan_subnet = lookup('defaults::lan_subnet'),  # e.g. '10.58.0.0/16' — pods to masquerade
  String[1] $wg_config,
) {
  # Packages
  package { ['wireguard-tools', 'iptables']:
    ensure => present,
  }

  # WireGuard config
  # Stored in /etc/wireguard/wg0.conf, picked up by wg-quick@wg0.service

  file { '/etc/wireguard':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  # PostUp/PostDown:
  #   1. MASQUERADE forwarded pod traffic out the tunnel
  #   2. Kill switch: drop anything from the LAN side that isn't leaving
  #      via the tunnel interface. Without this, if wg0 ever disappears
  #      (crashed service, failed reboot) while eth0 is still up, forwarded
  #      traffic would silently fall through to the container's normal
  #      LAN route and leak out unencrypted instead of being black-holed.
  #
  # Computed once and inserted into $wg_config directly (rather than via a
  # separate ini_setting layered on top of the File resource) - having two
  # resources manage the same file caused the File resource to overwrite
  # these lines every Puppet run (since $wg_config itself doesn't include
  # them), falsely triggering a service refresh/tunnel restart on every
  # agent run even though the end state never actually changed.

  $postup   = "PostUp = iptables -t nat -A POSTROUTING -s ${lan_subnet} -o ${vpn} -j MASQUERADE && iptables -A FORWARD -i ${lan} ! -o ${vpn} -j DROP"
  $postdown = "PostDown = iptables -t nat -D POSTROUTING -s ${lan_subnet} -o ${vpn} -j MASQUERADE && iptables -D FORWARD -i ${lan} ! -o ${vpn} -j DROP"

  # Insert both lines immediately before the [Peer] section header.
  $full_wg_config = regsubst($wg_config, '(\[Peer\])', "${postup}\n${postdown}\n\n\\1")

  file { '/etc/wireguard/wg0.conf':
    ensure  => file,
    require => File['/etc/wireguard'],
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    notify  => Service['wg-quick@wg0'],
    content => $full_wg_config,
  }

  # Restart policy override
  # Vendor unit ships with Restart=no. Without this, if wg-quick@wg0
  # crashes (rather than the whole container rebooting), the tunnel simply
  # stays down until someone notices - silent failure, no self-healing.
  # A drop-in avoids editing the package-owned unit file directly.

  file { '/etc/systemd/system/wg-quick@wg0.service.d':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/systemd/system/wg-quick@wg0.service.d/override.conf':
    ensure  => file,
    require => File['/etc/systemd/system/wg-quick@wg0.service.d'],
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => "[Service]\nRestart=on-failure\nRestartSec=5\n",
    notify  => [Exec['wireguard_systemd_reload'], Service['wg-quick@wg0']],
  }

  exec { 'wireguard_systemd_reload':
    command     => '/usr/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  # Service

  service { 'wg-quick@wg0':
    ensure  => running,
    enable  => true,
    require => [
      Package['wireguard-tools'],
      File['/etc/wireguard/wg0.conf'],
    ],
  }

  # IP forwarding
  # Must be enabled for the container to route pod traffic through the tunnel.

  sysctl { 'net.ipv4.ip_forward':
    ensure => present,
    value  => '1',
  }

  # Monitoring (optional remove if not using node_exporter)
  # Exposes wg show stats; scrape with a custom textfile collector if desired.
  # TODO: flesh out if you add prometheus-node-exporter to this container.
  include profile::monitoring::node_exporter
}
