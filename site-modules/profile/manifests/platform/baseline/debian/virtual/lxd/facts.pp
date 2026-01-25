#
#
class profile::platform::baseline::debian::virtual::lxd::facts {
<<<<<<< HEAD
  file { '/etc/puppetlabs/facter':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/etc/puppetlabs/facter/facts.d':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => File['/etc/puppetlabs/facter'],
  }

  file { '/etc/puppetlabs/facter/facts.d/lxd.yaml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @("EOF"),
      lxd:
        enabled: true
      | EOF
    require => File['/etc/puppetlabs/facter/facts.d'],
  }
}
