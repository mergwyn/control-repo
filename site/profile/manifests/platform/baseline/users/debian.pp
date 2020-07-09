# @summary users required for debian

class profile::platform::baseline::users::debian {

  User {
    ensure => present,
  }

  User { 'root_password':
    name     => 'root',
    password => lookup('defaults::sharedpassword'),
  }

  User { 'ubuntu': ensure => absent }
  User { 'sadmin':
    password   => lookup('defaults::sharedpassword'),
    groups     => 'sudo',
    uid        => 1000,
    managehome => true,
  }

# These files are all related to user profiles
  File {
    ensure => present,
  }

  file { '/root/.profile':
    source => 'file:///etc/skel/.profile',
  }
  file { '/root/.bashrc':
    source => 'puppet:///modules/profile/bashrc',
  }
  file { '/root/.bash_aliases':
    source => 'puppet:///modules/profile/bash_aliases',
  }
  file { '/etc/skel/.bashrc':
    source => 'puppet:///modules/profile/bashrc',
  }
  file { '/etc/skel/.bash_aliases':
    source => 'puppet:///modules/profile/bash_aliases',
  }
  file { '/etc/vim/vimrc.local':
    source => 'puppet:///modules/profile/vimrc.local',
  }

}
