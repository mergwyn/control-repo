#

class profile::reverse_proxy {

  # sort out certificates first
  class { ::letsencrypt:
    configure_epel => true,
    email          => hiera('defaults::adminemail'),
  }

  $domain = $facts['domain']
  letsencrypt::certonly { 'home':
    domains => [ $facts['fqdn'] ],
    plugin  => 'webroot',
    webroot_paths => ["/usr/share/nginx/html/$hostname"],
    #domains => [ $facts['fqdn'], "echo.$domain", "foxtrot.$domain", "tango.$domain",  "vpn.$domain" ],
    manage_cron => true,
    #cron_before_command => 'service nginx stop',
    #cron_success_command => '/bin/systemctl reload nginx.service',
    #suppress_cron_output => true,
  }

  # now for the reverse proxy
  class { 'nginx': }

  # now for servers - these can be moved to hiera
  nginx::resource::server { 'foxtrot.theclarkhome.com':
    listen_port => 80,
    proxy       => 'http://foxtrot.theclarkhome.com:80',
    #access_log  => '/var/log/nginx/foxtrot_access.log',
    #error_log   => '/var/log/nginx/foxtrot_error.log',
  }

  
  # Finally tidy up pound
  Package { "pound":             ensure => absent }
  file { '/etc/pound/pound.cfg': ensure => absent, }
  file { '/etc/pound':           ensure => absent, }
  file { '/etc/default/pound':   ensure  => absent, }
	
}
#
# vim: sw=2:ai:nu expandtab
