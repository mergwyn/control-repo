#
class profile::platform::baseline::debian::apparmor {

# TODO duplicated in docker module - work out solution
#  if !defined(Package['apparmor']) {
#    package { 'apparmor': }
#  }
#
#  service { 'apparmor':
#    ensure  => 'running',
#    enable  => true,
#    require => Package['apparmor']
#  }

}
