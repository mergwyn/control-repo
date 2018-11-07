#

class profile::mac::brew {
  # core stuff
  class { 'homebrew':
    user  => 'gary',
    group => 'wheel',
  }

  $brewpkglist = [ 'unison' ]
  $caskpkglist = [ 'munki' , 'puppet-agent-5' ]

  package { $brewpkglist:
    ensure   => latest,
    provider => brew,
  }

  package { $caskpkglist:
    ensure   => latest,
    provider => brewcask,
  }
}
# vim: sw=2:ai:nu expandtab
