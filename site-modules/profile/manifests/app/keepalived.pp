# @summary Keepalived
#

class profile::app::keepalived (
  Enum['MASTER', 'SLAVE'] $state = 'MASTER',
  String[1]               $lan = 'eth0',
  String[1]               $wan = 'eth1',
  String[1]               $vpn = 'tun0',
  Integer                 $vrid = 50,
  Integer                 $prio = 101,
  Stdlib::IP::Address::V4 $v_ip = "${lookup('defaults::subnet')}.2/${lookup('defaults::bits')}",
  # TODO use vpn_gateway not hard code $v_ip = "${lookup('defaults::vpn_gateway')}/${lookup('defaults::bits')}"
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

}
