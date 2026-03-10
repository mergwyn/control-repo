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

  kmod::load { 'ip_vs': }

# Define the list of scripts
  $lxd_scripts = [
    'allcontainers',
    'allhosts',
    'allremotes',
    'listcontainers',
    'listremotes',
    'upgrade_lxd',
  ]

# Iterate and create the file resources
  $lxd_scripts.each |String $script| {
    file { "/usr/local/bin/${script}":
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
      source => "puppet:///modules/profile/lxd/${script}",
    }
  }
}
