# @summary Policy routing for VPN-egress pods, via the zulu WireGuard gateway
#
# Marks traffic sourced from the vpn-gateway Multus range (10.58.0.50-59)
# and routes it via the zulu LXC container (10.58.0.24) instead of the
# node's normal default route.
#
# Applied to all k3s-prod nodes (charlie, delta, golf, hotel), since pods
# using the vpn-gateway NAD can schedule on any of them.
#
# Interim measure ahead of the Cilium EgressGatewayPolicy migration -
# same gateway container will be reused once Cilium is in place.
#
class profile::platform::baseline::debian::virtual::k3s::vpn_egress_routing (
  String[1] $gateway_ip   = '10.58.0.24',   # zulu, eth0
  String[1] $vpn_range    = '10.58.0.50-10.58.0.59',
  Integer   $fw_mark      = 100,
  Integer   $route_table  = 100,
) {
  # Ensure the custom routing table has a name (optional but readable
  # in `ip route show table vpn_egress` rather than a bare number).
  file_line { 'vpn_egress_rt_table_name':
    path  => '/etc/iproute2/rt_tables',
    line  => "${route_table} vpn_egress",
    match => "^${route_table}\\s",
  }

  # Mark packets sourced from the vpn-gateway pod IP range.
  exec { 'vpn_egress_mangle_mark':
    command => "/usr/sbin/iptables -t mangle -A PREROUTING -m iprange --src-range ${vpn_range} -j MARK --set-mark ${fw_mark}",
    unless  => "/usr/sbin/iptables -t mangle -C PREROUTING -m iprange --src-range ${vpn_range} -j MARK --set-mark ${fw_mark}",
    require => File_line['vpn_egress_rt_table_name'],
  }

  # Send marked packets to the custom table.
  exec { 'vpn_egress_ip_rule':
    command => "/usr/sbin/ip rule add fwmark ${fw_mark} table ${route_table}",
    unless  => "/usr/sbin/ip rule list | /usr/bin/grep -q 'fwmark 0x${fw_mark} lookup ${route_table}'",
    require => Exec['vpn_egress_mangle_mark'],
  }

  # Default route for the custom table: via zulu, not the node's normal gateway.
  exec { 'vpn_egress_ip_route':
    command => "/usr/sbin/ip route add default via ${gateway_ip} table ${route_table}",
    unless  => "/usr/sbin/ip route show table ${route_table} | /usr/bin/grep -q 'default via ${gateway_ip}'",
    require => Exec['vpn_egress_ip_rule'],
  }

  # NOTE: the exec resources above are not persistent across reboot on
  # their own - iptables/ip rule/ip route state needs to survive a node
  # restart. Options:
  #   - iptables-persistent + a systemd unit or netplan hook for ip rule/route
  #   - a small systemd oneshot service that reapplies all three at boot
  # Left as a follow-up once the routing is confirmed working; not required
  # for initial validation.
}
