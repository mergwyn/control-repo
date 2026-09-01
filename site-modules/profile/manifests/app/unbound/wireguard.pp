# @summary Split-DNS resolver for the zulu WireGuard gateway
#
# Runs Unbound on zulu (not a k3s node, so no ipvlan/netfilter-bypass
# concerns apply here - Unbound sees normal traffic like any other host).
#
# Pods routed through zulu (dispatcharr, qbittorrent, sabnzbd) point their
# DNS at this resolver instead of CoreDNS directly, giving them split
# resolution from a single upstream:
#   - queries for $cluster_domain (in-cluster service/pod names - e.g.
#     Plex, the mail pod, Prowlarr) are stubbed to CoreDNS, so cluster-
#     internal lookups keep working exactly as they do for any other pod
#   - everything else (trackers, indexers, news servers, general internet
#     names) is forwarded to PrivateVPN's own resolvers, over the tunnel -
#     closing the DNS-leak gap left by routing traffic through the VPN
#     while still resolving names via the node's normal path
#
# Binding to $gateway_ip (zulu's LAN-facing address, not just loopback)
# is what makes this resolver reachable from pods on the LAN side at all;
# 127.0.0.1 is also bound for local/remote-control tooling on zulu itself.
#
# $outgoing_interface pins Unbound's own upstream queries (i.e. the
# forward-zone lookups against PrivateVPN's resolvers) out via wg0
# specifically, rather than letting the OS pick a source interface - this
# guarantees DNS queries for non-cluster names are only ever sent over the
# tunnel, never leaking out zulu's own LAN/WAN path even if wg0's route
# table changes for some other reason.
#
# val_permissive_mode is enabled because DNSSEC validation would otherwise
# fail or add latency against PrivateVPN's resolvers, which are not
# expected to support/pass through DNSSEC reliably; permissive mode logs
# validation failures rather than hard-failing the query.
#
# unbound::remote is enabled for local diagnostics (unbound-control) when
# troubleshooting resolution issues on zulu directly.
#
# @param gateway_ip
#   zulu's LAN-facing IP. Unbound binds here so pods on the LAN/net1 side
#   can reach it directly, in addition to loopback.
# @param cluster_ip
#   CoreDNS's ClusterIP (k3s default convention: 10th address of the
#   service CIDR, e.g. 10.43.0.10 - confirm against the live cluster
#   rather than assuming, via:
#     kubectl get svc -n kube-system kube-dns -o jsonpath='{.spec.clusterIP}'
#   ). All queries for $cluster_domain are stubbed here.
# @param cluster_domain
#   The cluster's internal DNS suffix. Defaults to the Kubernetes
#   standard 'cluster.local'; only override if the cluster was built with
#   a non-default --cluster-domain.
#
class profile::app::unbound::wireguard (
  Stdlib::IP::Address::V4 $gateway_ip     = lookup('defaults::vpn::gateway'), # 10.58.0.24
  Stdlib::IP::Address::V4 $cluster_ip     = lookup('defaults::k3s::clusterIP'),
  String[1]               $cluster_domain = 'cluster.local',
) {
  class { 'unbound':
    interface              => [$gateway_ip, '127.0.0.1'],
    interface_automatic    => false,
    access                 => ["${lookup('defaults::lan_subnet')}", '127.0.0.0/8'],
    do_not_query_localhost => false,
    val_permissive_mode    => true,
    outgoing_interface     => [$facts['networking']['interfaces']['wg0']['ip']],
    control_enable         => true,
  }

  unbound::stub { $cluster_domain:
    address => [$cluster_ip],
    require => Class['unbound'],
  }

  unbound::forward { '.':
    address => lookup('defaults::vpn::nameservers'),
    require => Class['unbound'],
  }
}
