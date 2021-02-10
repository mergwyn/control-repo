# @summary host file entries for Debian

class profile::platform::baseline::debian::hosts {

  $ip = $trusted['extensions']['pp_role'] ? {
    'domain_controller' => $facts['networking']['ip'],
    default             => '127.0.1.1',
  }

  Host {
    ensure   => present,
  }

  host { $trusted['hostname']:
    ensure => absent,
    ip     => '127.0.1.1',
  }
  host { $trusted['certname']:
    ensure       => present,
    ip           => $ip,
    host_aliases => $trusted['hostname'],
  }
  host { 'localhost':
    ip           => '127.0.0.1',
    host_aliases => "localhost.${trusted['domain']}",
  }
  host { 'ip6-localhost':
    ip           => '::1',
    host_aliases => 'ip6-loopback',
  }
  host { 'ip6-localnet':
    ip => 'fe00::0',
  }
  host { 'ip6-mcastprefix':
    ip => 'ff00::0',
  }
  host { 'ip6-allnodes':
    ip => 'ff02::1',
  }
  host { 'ip6-allrouters':
    ip => 'ff02::2',
  }
  host { 'ip6-allhosts':
    ip => 'ff02::3',
  }

}
