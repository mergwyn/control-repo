#
class profile::platform::baseline::debian::apparmor {

  service { 'apparmor':
    ensure => 'running',
    enable => true,
  }

}
