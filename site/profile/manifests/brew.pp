#

class profile::brew {
  # core stuff
  class { 'homebrew':
    user  => 'gary',
    group => 'wheel',
  }

  $brewpkglist = [ 'unison' ]
  $caskpkglist = [ 'munki' ]

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
