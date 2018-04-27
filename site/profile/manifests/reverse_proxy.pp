#

class profile::reverse_proxy {

  # sort out certificates first
  #class { '::letsencrypt':
  #  config => {
  #    email  => hiera('defaults::adminemail'),
  #    server => 'https://acme-staging.api.letsencrypt.org/directory'
  #  }
  #}

  #$dir='/usr/share/nginx/html'
  $domain = $::facts['domain']
  #letsencrypt::certonly { 'home':
  #  domains       => [ $::facts['fqdn'] ],
  #  plugin        => 'webroot',
  #  webroot_paths => ["${dir}/${::hostname}"],
    #domains => [
    #  $facts['fqdn'],
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
  nginx::resource::server { "tango.${domain}":
    listen_port => 5050,
    proxy       => "http://tango.${domain}:5050",
  }
  #nginx::resource::server { "tango.${domain}":
  #  listen_port => 8080,
  #  proxy       => "http://tango.${domain}:8080",
  #}
  #nginx::resource::server { "tango.${domain}":
  #  listen_port => 8080,
  #  proxy       => "http://tango.${domain}:8080",
  #}

  
  # Finally tidy up pound
  Package { 'pound':             ensure => absent }
  file { '/etc/pound/pound.cfg': ensure => absent, }
  file { '/etc/pound':           ensure => absent, }
  file { '/etc/default/pound':   ensure  => absent, }
  
}
#
# vim: sw=2:ai:nu expandtab
