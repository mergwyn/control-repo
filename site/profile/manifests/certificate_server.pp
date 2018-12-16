#

class profile::certificate_server {

  # sort out certificates first
  #class { '::letsencrypt':
  #  config => {
  #    email  => hiera('defaults::adminemail'),
  #    server => 'https://acme-staging.api.letsencrypt.org/directory'
  #  }
  #}

  #$dir='/usr/share/nginx/html'
  $domain = $::facts['networking']['domain']
  #letsencrypt::certonly { 'home':
  #  domains       => [ $::facts['networking']['fqdn'] ],
  #  plugin        => 'webroot',
  #  webroot_paths => ["${dir}/${::hostname}"],
    #domains => [
    #  $facts['networking']['fqdn'],
    #  "echo.$domain",
    #  "foxtrot.$domain",
    #  "tango.$domain",
    #  "vpn.$domain"
    #],
    #webroot_paths => [
    #  "$dir/$hostname",
    #  "$dir/echo",
    #  "$dir/foxtrot",
    #  "$dir/tango",
    #  $dir/vpn"
    #],
    #manage_cron   => true,
    #cron_before_command => 'service nginx stop',
    #cron_success_command => '/bin/systemctl reload nginx.service',
    #suppress_cron_output => true,
  #}

  # now for the reverse proxy
  class { 'nginx': }

  # now for servers - these can be moved to hiera
  nginx::resource::server { "${::hostname}.${domain}":
    listen_port => 80,
    proxy       => "http://${::hostname}.${domain}:80",
  }
  nginx::resource::server { "foxtrot.${domain}":
    listen_port => 80,
    proxy       => "http://foxtrot.${domain}:80",
  }
  nginx::resource::server { "webmin.${domain}":
    listen_port => 80,
    proxy       => "http://${::hostname}.${domain}:10000",
  }
  nginx::resource::server { "zulu.${domain}":
    listen_port => 80,
    proxy       => "http://zulu.${domain}:80",
  }
  # tango related
  nginx::resource::server { "couchpototo.tango.${domain}":
    listen_port => 5050,
    server_name => [ "tango.${domain}" ],
    proxy       => "http://tango.${domain}:5050",
  }
  nginx::resource::server { "sabnzdb.tango.${domain}":
    listen_port => 8080,
    server_name => [ "tango.${domain}" ],
    proxy       => "http://tango.${domain}:8080",
  }
  nginx::resource::server { "sonarr.tango.${domain}":
    listen_port => 8989,
    server_name => [ "tango.${domain}" ],
    proxy       => "http://tango.${domain}:8989",
  }
  nginx::resource::server { "transmission.tango.${domain}":
    listen_port => 9091,
    server_name => [ "tango.${domain}" ],
    proxy       => "http://tango.${domain}:9091",
  }
  #
  nginx::resource::upstream { 'plex_upstream':
    members => [ "tango.${domain}:32400", ],
  }
  nginx::resource::server { "plex.tango.${domain}":
    listen_port => 32400,
    server_name => [ "tango.${domain}" ],
    access_log  => 'off',
    locations   => {
      '/web' => {
        location            => '/web',
        proxy               => "http://tango.${domain}:32400",
        proxy_buffering     => 'off',
        proxy_redirect      => 'off',
        proxy_http_version  => '1.1',
        proxy_set_header    => [
          'X-Forwarded-For $proxy_add_x_forwarded_for',
          'Upgrade $http_upgrade',
          'Connection $http_connection',
          'X-Real-IP $remote_addr',
          'Host $http_host',
        ],
        location_cfg_append => {
    #      'if ($http_x_plex_device_name = "")' => '{rewrite ^/$ https://$http_host/web/index.html}',
          'proxy_cookie_path' => '/web/ /',
        },
      },
    },
  }

  # Finally tidy up pound
  #Package { 'pound':             ensure => absent }
  #file { '/etc/pound/pound.cfg': ensure => absent, }
  #file { '/etc/pound':           ensure => absent, }
  #file { '/etc/default/pound':   ensure  => absent, }

}
#
# vim: sw=2:ai:nu expandtab
