#
class profile::platform::baseline::debian::apparmor {

# TODO duplicated in docker module - work out solution
  #package { 'apparmor': }

  #service { 'apparmor':
  #  ensure  => 'running',
  #  enable  => true,
  #  require => Package['apparmor']
  #}

}
