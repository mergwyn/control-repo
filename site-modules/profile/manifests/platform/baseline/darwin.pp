#
#
class profile::platform::baseline::darwin {

  include profile::platform::baseline::users::darwin
  include profile::platform::baseline::darwin::brew
  include profile::platform::baseline::darwin::timemachine
  include profile::platform::baseline::darwin::packages

  File {
    owner => 'root',
    group => 'admin',
    ensure => file,
  }

  file { '/etc/krb5.config':
    source => 'puppet:///modules/profile/mac/krb5.conf',
    group  => 'wheel',
  }
  file { '/etc/ssh/ssh_config':
    source => 'puppet:///modules/profile/mac/ssh_config',
    group  => 'wheel',
  }

}
