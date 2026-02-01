#
#
class profile::platform::baseline::debian::virtual::lxd {
  package { ['bridge-utils']: }
  package { ['criu']: ensure => absent }

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

  kmod::load { 'ip_vs': }

  exec { 'wait-for-lxd-cert':
    path    => ':/bin',
    command => 'true',
    unless  => 'test -f /var/snap/lxd/common/lxd/server.crt',
    require => Package['lxd'],
  }

  $certdir  = '/root/snap/lxd/common/config'
  $certpath = "${certdir}/client"

  file { $certdir:
    ensure => directory,
    mode   => '0700',
  }

  exec { 'lxd-generate-client-cert':
    path    => ':/bin',
    command => "openssl req -newkey rsa:4096 -nodes \
               -keyout ${certpath}.key \
               -x509 -days 3650 \
               -out ${certpath}.crt \
               -subj '/CN=lxd-puppet-client'",
    creates => "${certpath}.crt",
    require => File[$certdir],
  }

  file { "${certpath}.key": mode => '0600' }
  file { "${certpath}.crt": mode => '0644' }

  # Export our existence as a remote
  @@profile::app::lxd::remote { $facts['networking']['hostname']:
    fqdn => $facts['networking']['fqdn'],
    port => 8443,
  }
}
