#
class profile::mac::munki_client {
  if $::operatingsystem != 'Darwin' {
    fail('The munki_client module is only supported on Darwin/OS X')
  }

  file { ['/Library/Managed Installs', '/Library/Managed Installs/certs/' ]:
    ensure => directory,
    owner  => 'root',
    group  => 'wheel',
  }

  file { '/Library/Managed Installs/certs/ca.pem':
    mode    => '0640',
    owner   => root,
    group   => wheel,
    source  => '/etc/puppet/ssl/certs/ca.pem',
    require => File['/Library/Managed Installs/certs/'],
  }
 
  file { '/Library/Managed Installs/certs/clientcert.pem':
    mode    => '0640',
    owner   => root,
    group   => wheel,
    source  => "/etc/puppet/ssl/certs/${clientcert}.pem",
    require => File['/Library/Managed Installs/certs/'],
  }
 
  file { '/Library/Managed Installs/certs/clientkey.pem':
    mode    => '0640',
    owner   => root,
    group   => wheel,
    source  => "/etc/puppet/ssl/private_keys/${clientcert}.pem",
    require => File['/Library/Managed Installs/certs/'],
  }
}
#
# vim: sw=2:ai:nu expandtab
