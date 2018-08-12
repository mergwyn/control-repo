#

class profile::mac::timemachine_server {

  package { [ 'netatalk' ] : }
  service { [ 'netatalk' ] : }

  file_line { 'default':
    ensure => present,
    path   => '/etc/netatalk/AppleVolumes.default',
    line   => ':DEFAULT: options:upriv,usedots,noadouble',
    match  => '^:DEFAULT:',
  }
  file_line { 'timemachine':
    ensure => present,
    path   => '/etc/netatalk/AppleVolumes.default',
    line   => '/srv/timemachine "Time Machine" cnidscheme:dbd options:usedots,upriv,tm',
    match  => '^/srv/timemachine',
  }

  #ini_setting {'default':
  #  ensure            => present,
  #  path              => '/etc/netatalk/AppleVolumes.default',
  #  section           => '',
  #  key_val_separator => ' ',
  #  setting           => ':DEFAULT:',
  #  value             => 'options:upriv,usedots,noadouble',
  #}

  #ini_setting {'tm':
  #  ensure            => present,
  #  path              => '/etc/netatalk/AppleVolumes.default',
  #  section           => '',
  #  key_val_separator => ' ',
  #  setting           => '/srv/timemachine',
  #  value             => '"Time Machine" cnidscheme:dbd options:usedots,upriv,tm',
  #}

}

# vim: sw=2:ai:nu expandtab
#


