# @summary Keepalived
#
#
class profile::app::keepalived (
  Enum['MASTER','BACKUP'] $state = 'BACKUP',
  String[1]               $lan = 'eth0',
  String[1]               $wan = 'eth1',
  String[1]               $vpn = 'tun0',
  Integer                 $vrid = 50,
  Integer                 $prio = 101,
  Stdlib::IP::Address::V4 $v_ip = "${lookup('defaults::vpn_gateway')}",
  Stdlib::IP::Address::V4 $v_cidr = "${v_ip}/${lookup('defaults::bits')}",
  #Stdlib::IP::Address::V4 $v_ip = "${lookup('defaults::subnet')}.2/${lookup('defaults::bits')}",
  Stdlib::Email           $notification_email = lookup('defaults::adminemail'),
  Stdlib::Email           $notification_email_from = "keepalived@${trusted['domain']}",
) {
  # ping script
  $ping_script = '/usr/local/bin/keepalived_check.sh'
  file { $ping_script:
    ensure  => file,
    mode    => '0755',
    content => @("EOT"),
               #!/bin/bash
               /usr/bin/ping -c 1 -W 1 8.8.8.8 > /dev/null 2>&1
               | EOT
  }

  include keepalived

# Global defs
  class { 'keepalived::global_defs':
    notification_email      => $notification_email,
    notification_email_from => $notification_email_from,
    smtp_server             => 'localhost',
    smtp_connect_timeout    => '60',
    enable_script_security  => true,
    script_user             => 'root',
  }

  keepalived::vrrp::script { 'ping_google':
    script   => $ping_script,
    interval => 20,
    timeout  => 5,
    rise     => 3,
    fall     => 3,
    require  => File[$ping_script],
  }

# VRRP
  keepalived::vrrp::instance { 'VI_50':
    interface         => $lan,
    state             => $state,
    virtual_router_id => $vrid,
    priority          => $prio,
    auth_type         => 'PASS',
    auth_pass         => lookup('secrets::keepalived'),
    virtual_ipaddress => [ $v_cidr ],
    track_interface   => [ $wan, $vpn], # optional, monitor these interfaces.
    track_script      => 'ping_google',
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
