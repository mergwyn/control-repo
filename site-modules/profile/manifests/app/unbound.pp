# @summary Set up unbound DNS server
#
# @param lan
#   Interface to use to get the local address
#
# @param gateway
#   (virtual) ip address of the VPN gateway
#
class profile::app::unbound (
  String[1]               $lan     = 'eth0',
  Stdlib::IP::Address::V4 $gateway = lookup('defaults::vpn_gateway'),
) {

# TODO investigate why ip_transparent caused permission error

  systemd::dropin_file { 'keepalived.conf':
    ensure => absent,
    unit   => 'unbound.service',
  }

  include profile::platform::baseline::debian::apparmor
  file { '/etc/apparmor.d/local/usr.sbin.unbound':
    ensure  => file,
    notify  => Service['unbound', 'apparmor'],
    content => 'capability net_raw,',
  }

  service { 'systemd-resolved':
    ensure => 'stopped',
    enable => false,
  }
  -> class { 'unbound':
    interface              => [ $gateway, $facts['networking']['interfaces'][$lan]['ip'] ],
    interface_automatic    => false,
    access                 => [ "${lookup('defaults::cidr')}", '127.0.0.0/8' ],
    do_not_query_localhost => false,
    val_permissive_mode    => true,
    ip_transparent         => true,
    require                => Service['systemd-resolved'],
  }
  -> unbound::forward { $trusted['domain']:
    address => lookup('defaults::dns::nameservers'),
  }

# Enable unbound-resolvconf service
  service { 'unbound-resolvconf':
    ensure => 'running',
    enable => true,
  }

}
