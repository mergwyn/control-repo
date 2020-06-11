#
class profile::platform::baseline::debian::apparmor {

  package { 'apparmor': }

  service { 'apparmor':
    ensure  => 'running',
    enable  => true,
    require => Package['apparmor']
  }

}
