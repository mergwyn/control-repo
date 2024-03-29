#
#
class profile::app::openvpn::forwards {

  $plex  = '10.58.0.30'
  $proxy = '10.58.0.10'

# TODO move this to app modules and sonsume exported resources
#  [ 'plex', 'transmission-client' ].each |String $service| {
#    firewalld_rich_rule {"Forward ${service} from external zone to ${plex}":
#      ensure  => present,
#      zone    => 'external',
#      dest    => $plex,
#      service => $service,
#      action  => 'accept',
#    }
#  }

  [ 32400, 51413 ].each |Integer $port| {
    firewalld_rich_rule {"Forward tcp ${port} from external zone to ${plex}":
      ensure       => present,
      zone         => 'external',
      forward_port => {
        'port'     => $port,
        'protocol' => 'tcp',
        'to_port'  => $port,
        'to_addr'  => $plex,
      },
    }
  }
  [ 8989, 7878 , 8080, 9091, 9092 ].each |Integer $port| {
    firewalld_rich_rule {"Forward tcp ${port} from external zone to ${proxy}":
      ensure       => present,
      zone         => 'external',
      forward_port => {
        'port'     => $port,
        'protocol' => 'tcp',
        'to_port'  => $port,
        'to_addr'  => $proxy,
      },
    }
  }

  #add_port_forward sonarr_8989 vpnfirewall 8989 $proxy 8989
  #add_port_forward radarr_7878 vpnfirewall 7878 $proxy 7878
  #add_port_forward sab_8080 vpnfirewall 8080 $proxy 8080
  #add_port_forward http vpnfirewall 80 $proxy 443
  #add_port_forward https vpnfirewall 443 $proxy 443

}
