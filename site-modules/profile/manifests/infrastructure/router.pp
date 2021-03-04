#

class profile::infrastructure::router (
  Boolean $iptv = true,
  Enum['privavpn','none'] $type = 'none',
) {

  class {'firewalld':
    default_zone         => 'internal',
    default_service_zone => 'public',
    default_port_zone    => 'public',
  }
# TODO get interface from facts
  firewalld_zone {'internal':
    interfaces => ['eth0'],
    masquerade => true,
  }
  firewalld_zone {'public':
    interfaces => ['tun0'],
  }

# Lockdown services
  firewalld_service {'Disallow SSH in the public Zone':
    ensure  => absent,
    zone    => 'public',
    service => 'ssh',
  }
  firewalld_service {'Disallow dhcpv6-client in the public Zone':
    ensure  => absent,
    zone    => 'public',
    service => 'dhcpv6-client',
  }

# TODO move this to app modules and sonsume exported resources
  firewalld_service {'Allow plex in the public Zone':
    ensure  => present,
    zone    => 'public',
    service => 'plex',
  }
  firewalld_service {'Allow http in the public Zone':
    ensure  => present,
    zone    => 'public',
    service => 'http',
  }
  firewalld_service {'Allow https in the public Zone':
    ensure  => present,
    zone    => 'public',
    service => 'https',
  }

  case $type  {
    'none':      { }
    'privatvpn': { include profile::infrastructure::router::privatvpn }
    default:     { fail("${type} is not supported") }
  }

# TODO remove this
#  if $iptv {
#    include cron
#    include profile::app::scripts
#    $codedir='/opt/scripts'
#
#    # make sure routes are up to date
#    cron::job {'iptv-routes':
#      command     => "test -x ${codedir}/iptv/getroutes && ${codedir}/iptv/getroutes",
#      minute      => 30,
#      hour        => '4,12,16',
#      environment => [ 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' ],
#    }
#  }

}
