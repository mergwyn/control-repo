#

class profile::mac::brew {
  # core stuff
  exec {'brew xcode git install':
    path    => $facts['path'],
    command => 'xcode-select --install',
    creates => '/usr/bin/git',
  }
  class { 'homebrew':
    user      => 'sadmin',
    group     => 'wheel',
    multiuser => true,
    require   => Exec['brew xcode git install'],
  }

  $brewpkglist = [
    'unison',
  ]
  $caskpkglist = [
    'puppetlabs/puppet/puppet-agent-5',
  ]

  package { $brewpkglist:
    ensure   => present,
    provider => brew,
  }

  package { $caskpkglist:
    ensure   => present,
    provider => brewcask,
  }
}
# vim: sw=2:ai:nu expandtab
