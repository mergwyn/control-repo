#

class profile::infrastructure::router (
  Boolean $iptv = true,
  Enum['privatvpn','none'] $type = 'none',
) {

  class {'firewalld':
    default_zone         => 'internal',
    default_service_zone => 'public',
    default_port_zone    => 'public',
  }

# Attach interface to internal zone
  firewalld_zone {'internal':
    interfaces => [$facts['networking']['primary']],
    masquerade => true,
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
  firewalld_rich_rule {'Allow plex to plexserver from public zone':
    ensure  => present,
    zone    => 'public',
    dest    => '10.58.0.30',
    service => 'plex',
    action  => 'accept',
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
