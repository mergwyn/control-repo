#

class profile::app::openvpn::forwards {

  $plex  = '10.58.0.30'
  $proxy = '10.58.0.10'

# TODO move this to app modules and sonsume exported resources
  firewalld_rich_rule {'Forward plex from external zone':
    ensure  => present,
    zone    => 'external',
    dest    => $plex,
    service => 'plex',
    action  => 'accept',
  }

  firewalld_rich_rule {'Forward transmission from external zone':
    ensure  => present,
    zone    => 'external',
    dest    => $plex,
    service => 'transmission',
    action  => 'accept',
  }

  firewalld_rich_rule {'Forward http from external zone':
    ensure  => present,
    zone    => 'external',
    dest    => $proxy,
    service => 'http',
    action  => 'accept',
  }

  firewalld_rich_rule {'Forward https from external zone':
    ensure  => present,
    zone    => 'external',
    dest    => $proxy,
    service => 'https',
    action  => 'accept',
  }

  #add_port_forward sonarr_8989 vpnfirewall 8989 $proxy 8989
  #add_port_forward radarr_7878 vpnfirewall 7878 $proxy 7878
  #add_port_forward sab_8080 vpnfirewall 8080 $proxy 8080
  #add_port_forward https vpnfirewall 443 $proxy 443

}
