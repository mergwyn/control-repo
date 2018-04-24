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
    #domains => [ $facts['fqdn'], "echo.$domain", "foxtrot.$domain", "tango.$domain",  "vpn.$domain" ],
    manage_cron => true,
    #cron_before_command => 'service nginx stop',
    #cron_success_command => '/bin/systemctl reload nginx.service',
    #suppress_cron_output => true,
  }

  # now for the reverse proxy
  package { "pound": ensure => installed }

  file { '/etc/pound': ensure => 'directory', }

  file { '/etc/pound/pound.cfg':
     ensure  => file,
     require => Package["pound"],
     notify  => Service["pound"],
     source  => 'puppet:///modules/profile/pound/pound.cfg',
  }

  file { '/etc/default/pound':
     ensure  => file,
     require => Package["pound"],
     notify  => Service["pound"],
     source  => 'puppet:///modules/profile/pound/pound.default',
  }
	
  service { 'pound':
    ensure => running,
    subscribe => [
      Package['pound'],
      File['/etc/pound/pound.cfg'],
      File['/etc/default/pound'],
    ],
  }
	
}
#
# vim: sw=2:ai:nu expandtab
