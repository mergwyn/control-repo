#

class profile::puppet::repo {

  apt::source { 'puppet5':
    comment  => 'Puppet 5 bionic Repository',
    location => 'http://apt.puppetlabs.com',
    release  => 'bionic',
    repos    => 'puppet5',
    key      => {
      'id'     => '6F6B15509CF8E59E6E469F327F438280EF8D349F',
      'server' => 'pgp.mit.edu',
    },
  }
  $purgelist = [ 'pc_repo.list', 'pc_repo.list.distUpgrade' ]
  file { $purgelist: ensure => absent }
}
# vim: sw=2:ai:nu expandtab
