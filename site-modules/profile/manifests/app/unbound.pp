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
    content => @("EOT"),
               capability net_raw,
               | EOT
  }

  service { 'systemd-resolved':
    ensure => 'stopped',
    enable => false,
  }
  -> class { 'unbound':
    interface              => [ '127.0.0.1', $gateway, $facts['networking']['interfaces'][$lan]['ip'] ],
    interface_automatic    => false,
    access                 => [ "${lookup('defaults::cidr')}", '127.0.0.0/8' ],
    do_not_query_localhost => false,
    val_permissive_mode    => true,
    purge_unbound_conf_d   => false,
    ip_transparent         => true,
    require                => Service['systemd-resolved'],
  }
  unbound::stub { $trusted['domain']:
    address => lookup('defaults::dns::nameservers'),
  }
  class { 'unbound::remote': enable => true, }

# Enable unbound-resolvconf service
  service { 'unbound-resolvconf': enable => true, }

}
