#

class profile::mac::brew {
  # core stuff
  exec {'brew xcode git install':
    path    => $facts['path'],
    command => 'xcode-select --install',
    creates => '/usr/bin/git',
  }
  class { 'homebrew':
    user      => 'gary',
    group     => 'admin',
    multiuser => true,
    require   => Exec['brew xcode git install'],
  }
}
# vim: sw=2:ai:nu expandtab
