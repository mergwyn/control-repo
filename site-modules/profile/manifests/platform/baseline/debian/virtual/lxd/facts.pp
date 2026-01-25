#
#
class profile::platform::baseline::debian::virtual::lxd::facts {
  file { '/etc/puppetlabs/facter/facts.d/lxd.yaml':
    ensure  => file,
    mode    => '0644',
    content => @("EOF"),
      lxd:
        enabled: true
      | EOF
    require => Package['lxd'],
  }
}
