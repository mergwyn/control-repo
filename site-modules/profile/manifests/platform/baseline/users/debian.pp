# @summary users required for debian
#
class profile::platform::baseline::users::debian {
  User {
    ensure => present,
  }

  User { 'root_password':
    name     => 'root',
    password => lookup('secrets::root'),
  }

  User { 'ubuntu': ensure => absent }
  User { 'sadmin':
    password   => lookup('secrets::sadmin'),
    groups     => 'sudo',
    uid        => 1000,
    managehome => true,
  }

  # Make sure users have video and render groups if required
  $media_users = ['media']

  group { ['video', 'render']:
    ensure          => present,
    members         => $media_users,
    auth_membership => false,
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
