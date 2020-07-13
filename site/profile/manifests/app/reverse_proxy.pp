#
#
class profile::app::reverse_proxy {

  if $facts['os']['family'] != 'Debian' {
    fail("${title} is only for Debian")
  }

  if !defined(Class['ngnix']) {
    class{'nginx': server_purge => true, }
  }
  else {
    include nginx
  }

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

  package { 'python3-certbot-nginx': }

# This options file allows for a working nginx config even if the certs do not exist
# The hook below on certificate creation works together with the include_files in the host
  file { '/etc/nginx/options-ssl-nginx.conf':
    require => Package[nginx],
    content => @("EOT"/$),
               ssl_certificate           /etc/letsencrypt/live/${trusted['certname']}/fullchain.pem;
               ssl_certificate_key       /etc/letsencrypt/live/${trusted['certname']}/privkey.pem;
               | EOT
  }

  class { 'letsencrypt':
    email               => "ca@${facts['domain']}",
#TODO: add hook to link ssl options to snippets
    renew_cron_ensure   => 'present',
    renew_cron_minute   => 0,
    renew_cron_hour     => 6,
    renew_cron_monthday => '1-31/2',
  }

  letsencrypt::certonly { $trusted['certname']:
    plugin               => 'nginx',
    domains              => [
                              '%{trusted.domain}',
                              '%{trusted.certname}',
                              'foxtrot.%{trusted.domain}',
                              'tango.%{trusted.domain}',
                              'zulu.%{trusted.domain}',
#  "echo.%{trusted.domain}"
                            ],
    manage_cron          => true,
    cron_success_command => 'systemctl reload nginx',
    suppress_cron_output => true,
  }

  $certdir = '/etc/letsencrypt/live/%{trusted.certname}'
  $pem     = "${certdir}/fullchain.pem"
  $key     = "${certdir}/privkey.pem"

  nginx::resource::location { 'well-known':
    location                   => '^~ /.well-known/acme-challenge/',
    www_root                   => '/var/www/html/letsencrypt/',
    server                     => [
      $trusted['hostname'],
      foxtrot,
      tango,
      zulu,
    ],
    location_custom_cfg_append => { 'default_type' => 'text/plain;' },
  }

  nginx::resource::server { $trusted['hostname']:
    server_name   => [ $trusted['certname'] ],
    listen_port   => 80,
    ssl           => true,
    ssl_redirect  => true,
    ssl_cert      => $pem,
    ssl_key       => $key,
    include_files => [ '/etc/nginx/snippets/options-ssl-nginx.conf*' ]
  }

  nginx::resource::server { 'zulu':
    server_name => [ "zulu.${trusted['domain']}" ],
    proxy       => "http://zulu.${trusted['domain']}:80",
  }
  nginx::resource::server { 'foxtrot':
    server_name => [ "foxtrot.${trusted['domain']}" ],
    proxy       => "http://foxtrot.${trusted['domain']}:80",
  }
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
    server_name  => [ "tango.${trusted['domain']}" ],
    listen_port  => 9091,
    proxy        => "http://tango.${trusted['domain']}:9091",
    ssl_port     => 9092,
    ssl          => true,
    ssl_redirect => true,
    ssl_cert     => $pem,
    ssl_key      => $key,
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
