#

class profile::app::timemachine {

  if $facts['os']['family'] != 'Debian' {
    fail("${title} is only for Debian")
  }
  
  Class [profile::app::samba] -> Class[profile::app::timemachine]

  $path = '/srv/timemachine'
  $owner = 'timemachine'

  if versioncmp($facts['samba_version'], '4.8') >= 0 {
# Use SMB for TimeMachine
    include profile::app::samba

    ::samba::share { 'timemachine':
        path    => $path,
        owner   => $owner,
        mode    => '0755',
        options => {
          'comment'            => 'Time Machine',
          'fruit:time machine' => 'yes',
          'browseable'         => 'yes',
          'writeable'          => 'yes',
          'create mask'        => '0600',
          'directory mask'     => '0700',
        }
    }

  } else {
# Use AFP for TimeMachine
    file { $path:
      ensure => directory,
      owner  => $owner,
    }

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


# Set quota
# TODO: use parameter for TM quota ?

  file { "${path}/.com.apple.TimeMachine.quota.plist":
    owner   => $owner,
    mode    => '0600',
    require => File[$path],
    content => @("EOT"/)
               <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
               <plist version="1.0">
               <dict>
               <key>GlobalQuota</key>
               <integer>250000000000</integer>
               </dict>
               </plist>
               | EOT
  }

  file { "${path}/.com.apple.timemachine.supported":
    owner   => $owner,
    mode    => '0600',
    require => File[$path],
  }

}
