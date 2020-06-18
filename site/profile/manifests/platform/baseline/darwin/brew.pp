#

class profile::platform::baseline::darwin::brew {

  exec {'brew xcode git install':
    path    => $facts['path'],
    command => 'xcode-select --install',
    creates => '/usr/bin/git',
  }


  $packagename='git-osx-installer'
  $package="/var/cache/${packagename}.dmg"

  archive {$package:
    ensure   =>   present,
    provider => 'curl',
    source   => "https://sourceforge.net/projects/${packagename}/files/latest/download",
  }
  package { $packagename:
    ensure   => installed,
    provider => pkgdmg,
    source   => $package,
    require  => Archive[$package],
  }

  $home = '/Users/brew'

  user {'brew':
    gid        => 'admin',
    password   => lookup('secrets::brew'),
    iterations => 86956,
    salt       => 'b78fbae626c563458942fea9b35f160ab02274e8e1c6b2403b9c7c93785a3915',
    home       => $home,
    require    => File[$home],
  }

  file { $home:
    ensure  => directory,
    owner   => 'brew',
    group   => 'admin',
    require => User[brew],
  }

  class { 'homebrew':
    user         => 'brew',
    group        => 'admin',
    multiuser    => true,
    github_token => lookup('secrets::github::homebrew'),
    require      => [
      Package[$packagename],
      User['brew'],
    ],
  }

  sudo::conf { 'brew':
    content => 'gary ALL=(brew) NOPASSWD: /usr/local/bin/brew,/bin/bash',
  }

}
