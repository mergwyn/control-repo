#
#
class profile::platform::baseline::darwin::brew {
  exec { 'brew xcode git install':
    path    => $facts['path'],
    command => 'xcode-select --install',
    creates => '/usr/bin/git',
  }

  $packagename='git-osx-installer'
  $package="/opt/puppetlabs/puppet/cache/${packagename}.dmg"

#  archive {$package:
#    ensure   =>   present,
#    provider => 'curl',
#    source   => "https://sourceforge.net/projects/${packagename}/files/latest/download",
#  }
#  package { $packagename:
#    ensure   => installed,
#    provider => pkgdmg,
#    source   => $package,
#    require  => Archive[$package],
#  }

  $home = '/Users/brew'

  user { 'brew':
    gid        => 'admin',
    password   => lookup('secrets::brew'),
    iterations => 86956,
    salt       => 'b78fbae626c563458942fea9b35f160ab02274e8e1c6b2403b9c7c93785a3915',
    home       => $home,
  }

  file { $home:
    ensure  => directory,
    owner   => 'brew',
    group   => 'admin',
    require => User['brew'],
  }

  class { 'homebrew':
    user         => 'brew',
    group        => 'admin',
    multiuser    => true,
    github_token => lookup('secrets::github::homebrew'),
    require      => [
#      Package[$packagename],
      Exec['brew xcode git install'],
      User['brew'],
    ],
  }

  sudo::conf { 'brew':
    content => @(END),
      gary ALL=(brew) NOPASSWD: /usr/local/bin/brew,/bin/bash
      brew ALL=(root) NOPASSWD: /usr/bin/touch,/bin/rm,/bin/cp /bin/mv,/usr/sbin/chown
      END
  }

  exec { 'homebrew_auto_upgrade':
    path        => ['/opt/homebrew/bin', '/usr/bin', '/bin', '/usr/sbin', '/sbin'],
    cwd         => '/tmp',
    command     => '/bin/bash -l -c "/opt/homebrew/bin/brew update && /opt/homebrew/bin/brew upgrade --greedy"',
    environment => [
      "HOME=${home}",
      'HOMEBREW_NO_ENV_HINTS=1',
      'HOMEBREW_NO_AUTO_UPDATE=1',
    ],
    user        => 'brew',
    onlyif      => '/bin/bash -l -c "/opt/homebrew/bin/brew outdated --quiet 2>/dev/null" | /usr/bin/grep -E -q "^[a-zA-Z0-9_-]+"',
    timeout     => 600,
  }
}
