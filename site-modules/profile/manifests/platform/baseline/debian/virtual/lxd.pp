#
#
class profile::platform::baseline::debian::virtual::lxd {
  package { ['bridge-utils']: }
  package { ['criu']:
    ensure => absent,
  }

  include snap

  package { 'lxd':
    provider => snap,
  }

  exec { 'enable-criu':
    path    => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    command => 'snap set lxd criu.enable=true',
    onlyif  => 'test "$(snap get lxd criu.enable)" = "false"',
    require => Package['lxd'],
    notify  => Exec['snap.lxd.daemon.service'],
  }

  exec { 'snap.lxd.daemon.service':
    path        => '/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin',
    command     => 'snap run --command=reload lxd.daemon',
    require     => Package['lxd'],
    refreshonly => true,
  }

  include profile::platform::baseline::debian::virtual::lxd::facts

  # Support keepalived / IPVS in privileged containers
  kmod::load { 'ip_vs': }

  exec { 'wait-for-lxd-cert':
    path      => ['/bin', '/usr/bin'],
    command   => 'true',
    unless    => 'test -f /var/snap/lxd/common/lxd/server.crt',
    require   => Package['lxd'],
    logoutput => false,
  }

  $certdir = '/root/snap/lxd/common/config'
  file { $certdir:
    ensure => directory,
    mode   => '0700',
  }

  $certpath = "${certdir}/client"
  exec { 'lxd-generate-client-cert':
    path    => ['/usr/bin', '/bin'],
    command => "openssl req -newkey rsa:4096 -nodes \
               -keyout ${certpath}.key \
               -x509 -days 3650 \
               -out ${certpath}.crt \
               -subj '/CN=lxd-puppet-client'",
    creates => "${certpath}.crt",
    require => File[$certdir],
  }

  file { "${certpath}.key": mode => '0600', }
  file { "${certpath}.crt": mode => '0644', }

  @@profile::app::lxd::remote { $facts['networking']['hostname']:
    fqdn => $facts['networking']['fqdn'],
    port => 8443,
  }

  @@lxd::exported_client_cert { $facts['networking']['hostname']:
    cert => Sensitive(Deferred(file("${certpath}.crt"))),
    fqdn => $facts['networking']['fqdn'],
  }

}
