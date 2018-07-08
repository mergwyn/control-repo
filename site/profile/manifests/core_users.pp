#

class profile::core_users {
  # users and ssh access
  $passwordsalt = hiera('defaults::sharedpassword')
  user { 'root': password => "${passwordsalt}", }
  file { '/root/.profile':
    ensure => present,
    path   => '/root/.profile',
    source => 'file:///etc/skel/.profile',
  }
  file { '/root/.bashrc':
    ensure => present,
    path   => '/root/.bashrc',
    source => 'puppet:///modules/profile/bashrc',
  }
  file { '/root/.bash_aliases':
    ensure => present,
    path   => '/root/.bash_aliases',
    source => 'puppet:///modules/profile/bash_aliases',
  }
  file { '/etc/skel/.bashrc':
    ensure => present,
    path   => '/etc/skel/.bashrc',
    source => 'puppet:///modules/profile/bashrc',
  }
  file { '/etc/skel/.bash_aliases':
    ensure => present,
    path   => '/etc/skel/.bash_aliases',
    source => 'puppet:///modules/profile/bash_aliases',
  }
  user { 'ubuntu': ensure => absent }
  user { 'sadmin':
    password   => "${passwordsalt}",
    groups     => 'sudo',
    uid        => '1000',
    managehome => true,
  }
}
# vim: sw=2:ai:nu expandtab
