# @summary Set up unbound DNS server
#
# @param lan
#   Interface to use to get the local address
#
# @param gateway
#   (virtual) ip address of the VPN gateway
#
class profile::app::unbound (
  #String[1]               $lan     = 'eth0',
  #Stdlib::IP::Address::V4 $gateway = lookup('defaults::vpn_gateway'),
) {

# TODO investigate why ip_transparent caused permission error

  systemd::dropin_file { 'keepalived.conf':
    ensure => absent,
    unit   => 'unbound.service',
  }
  class { 'systemd':
    resolved_ensure => 'stopped',
  }


  class { 'unbound':
    #interface              => [ $gateway, $facts['networking']['interfaces'][$lan]['ip'] ],
    interface              => [ '0.0.0.0' ],
    interface_automatic    => true,
    access                 => [ "${lookup('defaults::cidr')}", '127.0.0.0/8' ],
    do_not_query_localhost => false,
    val_permissive_mode    => true,
    ip_transparent         => true,
    username               => 'root',  # needed for ip_transparent
  }
  unbound::forward { $trusted['domain']:
    address => lookup('defaults::dns::nameservers'),
  }

# Enable unbound-resolvconf service
  service { 'unbound-resolvconf':
    ensure => 'running',
  }

}
