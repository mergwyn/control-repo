#

class profile::os::debian::base {
  # core stuff
  host { $facts['networking']['hostname']:
    ensure => absent,
    ip     => '127.0.1.1',
  }
  host { $facts['networking']['fqdn']:
    ensure       => present,
    host_aliases => $facts['networking']['hostname'],
    ip           => '127.0.1.1',
  }
}
