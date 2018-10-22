#
# TODO: 

class profile::mono () {

  apt::source { 'mono':
    location => 'deb https://download.mono-project.com/repo/ubuntu',
    release  => "stable-$::facts['os']['distro']['codename']",
    repos    => 'main',
    key      => {
      'id'     => '3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF',
      'server' => 'keyserver.ubuntu.com',
    },
  }
  package { [ 'mono-complete' ] : }

}
# vim: sw=2:ai:nu expandtab
