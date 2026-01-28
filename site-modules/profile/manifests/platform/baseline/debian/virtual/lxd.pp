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

  $trust_password = lookup('secrets::lxd::trust_password')
  exec { 'lxd-set-trust-password':
    command => "/usr/sbin/lxc config set core.trust_password '${trust_password}'",
    unless  => "/usr/sbin/lxc config get core.trust_password | grep -qx '${trust_password}'",
    path    => ['/usr/bin', '/usr/sbin'],
    require => Package['lxd'],
  }
}
