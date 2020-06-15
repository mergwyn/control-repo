#

class profile::platform::baseline::darwin::brew {

  exec {'brew xcode git install':
    path    => $facts['path'],
    command => 'xcode-select --install',
    creates => '/usr/bin/git',
  }

  class { 'homebrew':
    user         => 'gary',
    group        => 'admin',
    multiuser    => true,
    github_token => lookup('secrets::github::homebrew'),
    require      => [
      Exec['brew xcode git install'],
      User['brew'],
    ],
  }
}
