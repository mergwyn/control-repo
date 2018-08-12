#

class profile::mac::timemachine_server {

  package { [ 'netatalk' ] : }

  ini_setting {'default':
    ensure            => present,
    path              => '/etc/netatalk/AppleVolumes.default',
    section           => '',
    key_val_separator => '',
    setting           => ':DEFAULT:',
    value             => 'options:upriv,usedots,noadouble',
  }

  ini_setting {'tm':
    ensure            => present,
    path              => '/etc/netatalk/AppleVolumes.default',
    section           => '',
    key_val_separator => '',
    setting           => '/srv/timemachine',
    value             => '"Time Machine" cnidscheme:dbd options:usedots,upriv,tm',
  }

}

# vim: sw=2:ai:nu expandtab
#


