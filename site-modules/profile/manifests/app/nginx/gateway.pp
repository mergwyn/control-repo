# @summary Set up secure nginx reverse proxy
#
class profile::app::nginx::gateway (
  Stdlib::Absolutepath $nginx_conf = '/etc/nginx/options-ssl-nginx.conf',
  Stdlib::Absolutepath $certdir    = "/etc/letsencrypt/live/${trusted['certname']}",
) {
# TODO find a way of providing a common list of certs

  if $facts['os']['family'] != 'Debian' {
    fail("${title} is only for Debian")
  }

  if !defined(Class['ngnix']) {
    class{'nginx': server_purge => true, }
  }
  include profile::app::nginx

# Create the directories for the well known location used by letsencrypt
  file {'/var/www/html/letsencrypt/':
    ensure  => directory,
    require => Package[nginx],
  }
  file {'/var/www/html/letsencrypt/.well-known':
    ensure  => directory,
    require => Package[nginx],
  }
  file {'/var/www/html/letsencrypt/.well-known/acme-challenge/':
    ensure  => directory,
    require => Package[nginx],
  }

  $pem     = "${certdir}/fullchain.pem"
  $key     = "${certdir}/privkey.pem"

# TODO pass in hosts as variable?
  nginx::resource::location { 'well-known':
    location                   => '^~ /.well-known/acme-challenge/',
    www_root                   => '/var/www/html/letsencrypt/',
    server                     => [
      $trusted['hostname'],
#      foxtrot,
      tango,
#      zulu,
    ],
    location_custom_cfg_append => { 'default_type' => 'text/plain;' },
  }

  nginx::resource::server { $trusted['hostname']:
    server_name   => [ $trusted['certname'] ],
    listen_port   => 80,
    ssl           => true,
    ssl_redirect  => true,
    ssl_cert      => false,
    ssl_key       => false,
    include_files => [ '/etc/nginx/snippets/options-ssl-nginx.conf*' ],
  }

#  nginx::resource::server { 'zulu':
#    server_name => [ "zulu.${trusted['domain']}" ],
#    proxy       => "http://zulu.${trusted['domain']}:80",
#  }
#  nginx::resource::server { 'foxtrot':
#    server_name => [ "foxtrot.${trusted['domain']}" ],
#    proxy       => "http://foxtrot.${trusted['domain']}:80",
#  }
#  nginx::resource::server { 'echo':
#    server_name => [ "echo.${trusted['domain']}" ],
#    proxy       => "http://echo.${trusted['domain']}:80",
#  }
  # tango related
  nginx::resource::server { 'tango':
    server_name => [ "tango.${trusted['domain']}" ],
  }
  nginx::resource::server { 'tango-sabnzbd':
    server_name => [ "tango.${trusted['domain']}" ],
    listen_port => 8080,
    proxy       => "http://tango.${trusted['domain']}:8080",
  }
  nginx::resource::server { 'tango-radarr':
    server_name => [ "tango.${trusted['domain']}" ],
    listen_port => 7878,
    proxy       => "http://tango.${trusted['domain']}:7878",
  }
  nginx::resource::server { 'tango-sonarr':
    server_name => [ "tango.${trusted['domain']}" ],
    listen_port => 8989,
    proxy       => "http://tango.${trusted['domain']}:8989",
  }
  nginx::resource::server { 'tango-transmission':
    server_name   => [ "tango.${trusted['domain']}" ],
    listen_port   => 9091,
    proxy         => "http://tango.${trusted['domain']}:9091",
    ssl_port      => 9092,
    ssl           => true,
    ssl_redirect  => true,
    ssl_cert      => false,
    ssl_key       => false,
    include_files => [ '/etc/nginx/snippets/options-ssl-nginx.conf*' ]
  }
#  #
##  nginx::resource::upstream { 'plex_upstream':
##    members => [ "tango.$trusted['domain']:32400", ],
##  }
##  nginx::resource::server { 'plex.tango':
##    listen_port => 32400,
##    server_name => [ "tango.$trusted['domain']" ],
##    access_log  => 'off',
##    locations   => {
##      '/web' => {
##        location            => '/web',
##        proxy               => "http://tango.$trusted['domain']:32400",
##        proxy_buffering     => 'off',
##        proxy_redirect      => 'off',
##        proxy_http_version  => '1.1',
##        proxy_set_header    => [
##          'X-Forwarded-For $proxy_add_x_forwarded_for',
##          'Upgrade $http_upgrade',
##          'Connection $http_connection',
##          'X-Real-IP $remote_addr',
##          'Host $http_host',
##        ],
##        location_cfg_append => {
##    #      'if ($http_x_plex_device_name == "")' => '{rewrite ^/$ https://$http_host/web/index.html}',
##          'proxy_cookie_path' => '/web/ /',
##        },
##      },
##    },
##  }
#

}
