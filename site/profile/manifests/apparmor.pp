#
class profile::apparmor {
  package { 'apparmor': }

  service { 'apparmor':
    ensure  => 'running',
    enable  => true,
    require => Package['apparmor']
  }

}
# vim: sw=2:ai:nu expandtab
