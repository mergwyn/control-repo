#

# In order from least trusted to most trusted, the predefined zones within firewalld are:

# * drop:
#   The lowest level of trust. All incoming connections are dropped
#   without reply and only outgoing connections are possible.
# * block:
#   Similar to the above, but instead of simply dropping connections,
#   incoming requests are rejected with an icmp-host-prohibited or
#   icmp6-adm-prohibited message.
# * public:
#   Represents public, untrusted networks. You don’t trust other
#   computers but may allow selected incoming connections on a
#   case-by-case basis.
# * external:
#   External networks in the event that you are using the firewall as
#   your gateway. It is configured for NAT masquerading so that your
#   internal network remains private but reachable.
# * internal:
#   The other side of the external zone, used for the internal portion of
#   a gateway. The computers are fairly trustworthy and some additional
#   services are available.
# * dmz:
#   Used for computers located in a DMZ (isolated computers that will
#   not have access to the rest of your network). Only certain incoming
#   connections are allowed.
# * work:
#   Used for work machines. Trust most of the computers in the network.
#   A few more services might be allowed.
# * home:
#   A home environment. It generally implies that you trust most of the
#   other computers and that a few more services will be accepted.
# * trusted:
#   Trust all of the machines in the network. The most open of the
#   available options and should be used sparingly.

class profile::infrastructure::router (
  Boolean $iptv = true,
  Enum['privatvpn','none'] $type = 'none',
) {

  class {'firewalld':
# TODO add hashes for configuration
  }

# Attach interface to home zone
  firewalld_zone {'home':
    interfaces => [$facts['networking']['primary']],
    masquerade => true,
  }

# Lockdown services
  firewalld_service {'Disallow SSH in the external Zone':
    ensure  => absent,
    zone    => 'external',
    service => 'ssh',
  }
  firewalld_service {'Disallow dhcpv6-client in the external Zone':
    ensure  => absent,
    zone    => 'external',
    service => 'dhcpv6-client',
  }

# TODO move this to app modules and sonsume exported resources
  firewalld_rich_rule {'Allow plex to plexserver from external zone':
    ensure  => present,
    zone    => 'external',
    dest    => '10.58.0.30',
    service => 'plex',
    action  => 'accept',
  }
  firewalld_service {'Allow http in the external Zone':
    ensure  => present,
    zone    => 'external',
    service => 'http',
  }
  firewalld_service {'Allow https in the external Zone':
    ensure  => present,
    zone    => 'external',
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
