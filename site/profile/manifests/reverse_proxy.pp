#

class profile::reverse_proxy {

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
