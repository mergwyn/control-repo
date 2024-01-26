# @summary Keepalived settings for dns failovere
#
#
class profile::app::keepalived::dns (
  Stdlib::IP::Address::V4        $v_ip        = lookup('defaults::dns::vip'),
  Array[Stdlib::IP::Address::V4] $nameservers = lookup('defaults::dns::nameservers')
) {

  include profile::app::keepalived::notify

# Add virtual server for DNS
  keepalived::lvs::virtual_server { 'VPN_DNS':
    ip_address => $v_ip,
    port       => 53,
    delay_loop => 6,
    ha_suspend => true,
    lb_algo    => 'wrr',
    lb_kind    => 'DR',
    # TODO remove? persistence_timeout => 0,
    protocol   => 'TCP'
  }

  $nameservers.each |Integer $index, String $real_ip| {
    keepalived::lvs::real_server { "VPN_DNS_${index}":
      virtual_server => 'VPN_DNS',
      ip_address     => $real_ip,
      port           => 53,
      options        => {
        weight      => 1,
        notify_down => "'/sbin/ipvsadm -d -u ${v_ip}:53 -r ${real_ip}:53'",
        notify_up   => "'/sbin/ipvsadm -a -u ${v_ip}:53 -r ${real_ip}:53 -g -w 1'",
        'TCP_CHECK' => {
          connect_timeout => '3',
        }
      }
    }
  }

}
