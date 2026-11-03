# @summary zfs snappshotter install and configuration
#
class profile::platform::baseline::debian::zfs::snapshotter (
  String $type   = 'pyznap',
  Hash $settings = {},
) {
  # Setup default settings for all types
  $owner          = lookup('defaults::system_user')
  $group          = lookup('defaults::system_group')
  $adminemail     = lookup('defaults::adminemail')

  file { $configdir:
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    require => Class['sssd'],
  }
  $defaults = {
    path    => $target_ini,
    require => File[$configdir],
  }

  $default_settings = {
    'default' => {
      'frequent' => '4',
      'hourly'   => '24',
      'daily'    => '7',
      'weekly'   => '4',
      'monthly'  => '3',
      'yearly'   => '0',
    },
    'rpool' => {
      'snap'     => 'no',
      'clean'    => 'yes',
    },
    'rpool/ROOT' => {
      'snap' => 'yes',
    },
    'rpool/home' => {
      'snap' => 'yes',
    },
  }
  inifile::create_ini_settings($default_settings + $settings, $defaults)

  case $type {
    'sanoid': {
      $datasets = $default_settings + $settings
      $keymap   = { 'snap' => 'autosnap', 'clean' => 'autoprune', 'frequent' => 'frequently' }

      # Puppet won't remove the old cron when the pyznap branch drops out of the catalog
      cron::job { 'pyznap': ensure => absent }

      package { 'sanoid': ensure => installed }
      -> file { '/etc/sanoid': ensure => directory }
      -> file { '/etc/sanoid/sanoid.conf':
        ensure  => file,
        mode    => '0644',
        content => epp('profile/platform/baseline/debian/zfs/sanoid.conf.epp',
                        { datasets => $datasets, keymap => $keymap }),
      }
      ~> service { 'sanoid.timer':
        ensure => running,
        enable => true,
      }
      package { 'zfs-auto-snapshot': ensure => absent }
    }
    'pyznap': {
      $codedir        = '/opt'
      $target         = "${codedir}/pyznap"
      $configdir      = '/etc/pyznap'
      $target_ini     = "${configdir}/pyznap.conf"
      $link           = '/usr/local/bin/pyznap'

      $venv           = "${target}/venv"

      file { $target:
        ensure  => directory,
        owner   => $owner,
        group   => $group,
        require => Class['sssd'],
      }
      -> python::pyvenv { $venv: # install dependencies
        ensure     => present,
        version    => 'system',
        systempkgs => true,
        owner      => $owner,
        group      => $group,
        require    => File[$target],
      }
      -> python::pip { $type:
        ensure       => '1.6.0',
        pkgname      => $type,
        pip_provider => 'pip',
        virtualenv   => $venv,
        owner        => $owner,
        group        => $group,
        timeout      => 1800,
      }

      file { $link:
        ensure    => 'link',
        target    => "${venv}/bin/pyznap",
        subscribe => File[$venv],
      }

      cron::job { 'pyznap':
        user        => root,
        minute      => '*/15',
        environment => ['PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/sbin:/usr/local/bin"'],
        command     => '/opt/pyznap/venv/bin/pyznap snap >> /var/log/pyznap.log 2>&1',
      }

      logrotate::rule { 'pyznap':
        path         => '/var/log/pyznap.log',
        rotate       => 7,
        rotate_every => 'day',
      }

      package { 'zfs-auto-snapshot': ensure => absent }
    }

    'zfs-auto-snapshot': {
      package { 'zfs-auto-snapshot': }
    }
    default: {
    }
  }
}
