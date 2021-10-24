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
  Boolean                 $use_systemd_resolved = lookup('defaults::vpn::use_systemd_resolved'),
) {

# Add net_raw to allow ip_transparent to work
  include profile::platform::baseline::debian::apparmor
  file { '/etc/apparmor.d/local/usr.sbin.unbound':
    ensure  => file,
    notify  => Service['apparmor'],
    before  => Package['unbound'],
    content => @("EOT"),
               capability net_raw,
               | EOT
  }

# These interfaces are common
  $interfaces = [ $gateway, $facts['networking']['interfaces'][$lan]['ip'] ]

  case  $use_systemd_resolved {
    false: {
      # unbound replaces systemd-resolved so disable
      service { 'systemd-resolved':
        ensure => 'stopped',
        enable => false,
      }
      # No systemd-resolved listening on lo
      $interface_list = [ '127.0.0.1',] + $interfaces

      # Use local DNS servers for local domain
      unbound::stub { $trusted['domain']:
        address => lookup('defaults::dns::nameservers'),
        require => Class['unbound'],
      }
      # Enable unbound-resolvconf service
      # TODO check whether this is needed
      #  service { 'unbound-resolvconf': enable => true, }
      $purge_unbound_conf_d  = false

    }
    default: {
      # unbound acts as stub resolver forwarding to  systemd-resolved
      service { 'systemd-resolved':
        ensure => 'running',
        enable => true,
      }
      $interface_list = $interfaces

      service { 'unbound-resolvconf': enable => false, status => stopped, }
      # Just ship to systemd-resolved
      unbound::forward { '.':
        address => [ '127.0.0.53' ],
        require => Class['unbound'],
      }
      $purge_unbound_conf_d = true
    }
  }

# TODO for some reason not all of the config is applied on the first run
# TODO in particular ip_transparent is not set causing unbound service start to fail
# TODO work out why this is the case!
  class { 'unbound':
    interface              => $interface_list,
    interface_automatic    => false,
    access                 => [ "${lookup('defaults::cidr')}", '127.0.0.0/8' ],
    do_not_query_localhost => false,
    val_permissive_mode    => true,
    purge_unbound_conf_d   => $purge_unbound_conf_d,
    ip_transparent         => true,
    require                => Service['systemd-resolved'],
  }
  class { 'unbound::remote':
    enable  => true,
    require => Class['unbound'],
  }

}
