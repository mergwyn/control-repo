#

class profile::reverse_proxy {
  include nginx

  nginx::resource::server { 'webmin':
    listen_port => 1000,
    server_name => [ "${::hostname}.$::domain" ],
    proxy       => "http://${::hostname}.$::domain:10000",
  }
  nginx::resource::server { 'zulu':
    server_name => [ "zulu.$::domain" ],
    listen_port => 80,
    proxy       => "http://zulu.$::domain:80",
  }
  nginx::resource::server { 'foxtrot':
    server_name => [ "foxtrot.$::domain" ],
    listen_port => 80,
    proxy       => "http://foxtrot.$::domain:80",
  } 
  # tango related
  nginx::resource::server { 'couchpototo.tango':
    listen_port => 5050,
    server_name => [ "tango.$::domain" ],
    proxy       => "http://tango.$::domain:5050",
  }
  nginx::resource::server { 'sabnzbd.tango':
    listen_port => 8080,
    server_name => [ "tango.$::domain" ],
    proxy       => "http://tango.$::domain:8080",
  }
  nginx::resource::server { 'radarr.tango':
    listen_port => 7878,
    server_name => [ "tango.$::domain" ],
    proxy       => "http://tango.$::domain:7878",
  }
  nginx::resource::server { 'sonarr.tango':
    listen_port => 8989,
    server_name => [ "tango.$::domain" ],
    proxy       => "http://tango.$::domain:8989",
  }
  nginx::resource::server { 'transmission.tango':
    listen_port => 9091,
    server_name => [ "tango.$::domain" ],
    proxy       => "http://tango.$::domain:9091",
  }
  #
#  nginx::resource::upstream { 'plex_upstream':
#    members => [ "tango.$::domain:32400", ],
#  }
#  nginx::resource::server { 'plex.tango':
#    listen_port => 32400,
#    server_name => [ "tango.$::domain" ],
#    access_log  => 'off',
#    locations   => {
#      '/web' => {
#        location            => '/web',
#        proxy               => "http://tango.$::domain:32400",
#        proxy_buffering     => 'off',
#        proxy_redirect      => 'off',
#        proxy_http_version  => '1.1',
#        proxy_set_header    => [
#          'X-Forwarded-For $proxy_add_x_forwarded_for',
#          'Upgrade $http_upgrade',
#          'Connection $http_connection',
#          'X-Real-IP $remote_addr',
#          'Host $http_host',
#        ],
#        location_cfg_append => {
#    #      'if ($http_x_plex_device_name == "")' => '{rewrite ^/$ https://$http_host/web/index.html}',
#          'proxy_cookie_path' => '/web/ /',
#        },
#      },
#    },
#  }
  
  # Finally tidy up pound
  Package { 'pound':             ensure => absent }
  file { '/etc/pound/pound.cfg': ensure => absent, }
  file { '/etc/default/pound':   ensure  => absent, }
  file { '/etc/pound':
    ensure => absent,
    force  => true,
  }
  
}
#
# vim: sw=2:ai:nu expandtab
