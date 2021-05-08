# @summary Keepalived
#

class profile::app::keepalived (
  Enum['MASTER', 'SLAVE'] $state = 'MASTER',
  String[1]               $lan = 'eth0',
  String[1]               $wan = 'eth1',
  String[1]               $vpn = 'tun0',
  Integer                 $vrid = 50,
  Integer                 $prio = 101,
  Stdlib::IP::Address::V4 $v_ip = "${lookup('defaults::vpn_gateway')}/${lookup('defaults::bits')}",
  #Stdlib::IP::Address::V4 $v_ip = "${lookup('defaults::subnet')}.2/${lookup('defaults::bits')}",
) {

  include keepalived

  keepalived::vrrp::instance { 'VI_50':
    interface         => $lan,
    state             => $state,
    virtual_router_id => $vrid,
    priority          => $prio,
    auth_type         => 'PASS',
    auth_pass         => 'secret', # TODO sort out password
    virtual_ipaddress => [ $v_ip ],
    track_interface   => [ $wan, $vpn], # optional, monitor these interfaces.
  }

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

  $virtual_servers = lookup('defaults::vpn::servers')

  $virtual_servers.each |Integer $index, String $real_ip| {
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
