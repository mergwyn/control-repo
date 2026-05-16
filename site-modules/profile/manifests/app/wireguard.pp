# @summary WireGuard VPN tunnel for egress routing
#
# Runs a WireGuard tunnel in an LXC container, providing a routed egress
# point for Cilium EgressGatewayPolicy. Designed to be deployed on two
# containers (one per node) pointing at different PrivateVPN endpoints
# for active/active resilience.
#
# The container needs:
#   - NET_ADMIN capability (set in LXC profile)
#   - wireguard kernel module on host (built-in on Ubuntu 24.04)
#
# Cilium EgressGatewayPolicy should reference both container IPs.
#
## Wireguard configs
# The manifest assumes the config only contains one Interface and 1 Peer
# and that The Interface section is before the Peer section
#
class profile::app::wireguard (
  String[1] $lan        = 'eth0',   # interface facing k8s nodes
  String[1] $vpn        = 'wg0',    # WireGuard interface name
  String[1] $wg_config  = lookup('secrets::privatevpn::wg::wg1::config'),
  String[1] $lan_subnet = lookup('profile::app::wireguard::lan_subnet'),       # e.g. '10.58.0.0/16' — pods to masquerade
) {
  # ── Packages ────────────────────────────────────────────────────────────────

  package { ['wireguard-tools', 'iptables']:
    ensure => present,
  }

  # ── WireGuard config ─────────────────────────────────────────────────────────
  # Stored in /etc/wireguard/wg0.conf, picked up by wg-quick@wg0.service

  file { '/etc/wireguard':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  file { '/etc/wireguard/wg0.conf':
    ensure  => file,
    require => File['/etc/wireguard'],
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    notify  => Service['wg-quick@wg0'],
    content => $wg_config,
  }

  ini_setting { 'wireguard_postup':
    ensure  => present,
    path    => '/etc/wireguard/wg0.conf',
    section => 'Interface',
    setting => 'PostUp',
    value   => "iptables -t nat -A POSTROUTING -s ${lan_subnet} -o ${vpn} -j MASQUERADE",
  }

  ini_setting { 'wireguard_postdown':
    ensure  => present,
    path    => '/etc/wireguard/wg0.conf',
    section => 'Interface',
    setting => 'PostDown',
    value   => "iptables -t nat -D POSTROUTING -s ${lan_subnet} -o ${vpn} -j MASQUERADE",
  }

  File['/etc/wireguard/wg0.conf']
    -> Ini_setting['wireguard_postup']
    -> Ini_setting['wireguard_postdown']
    ~> Service['wg-quick@wg0']

  # ── Service ──────────────────────────────────────────────────────────────────

  service { 'wg-quick@wg0':
    ensure  => running,
    enable  => true,
    require => [
      Package['wireguard-tools'],
      File['/etc/wireguard/wg0.conf'],
    ],
  }

  # ── IP forwarding ─────────────────────────────────────────────────────────────
  # Must be enabled for the container to route pod traffic through the tunnel.

  sysctl { 'net.ipv4.ip_forward':
    ensure => present,
    value  => '1',
  }

  # ── Monitoring (optional — remove if not using node_exporter) ────────────────
  # Exposes wg show stats; scrape with a custom textfile collector if desired.
  # Placeholder — flesh out if you add prometheus-node-exporter to this container.

  # include profile::monitoring::node_exporter
}
