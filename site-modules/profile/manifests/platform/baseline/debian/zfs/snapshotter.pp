# @summary zfs snappshotter install and configuration
#
class profile::platform::baseline::debian::zfs::snapshotter (
  String $type = 'pyznap',
  $settings = null,
){

  case $type {
    'pyznap': {
      $codedir        = '/opt'
      $target         = "${codedir}/pyznap"
      $configdir      = '/etc/pyznap'
      $target_ini     = "${configdir}/pyznap.conf"

      $venv           = "${target}/venv"

      $owner          = lookup('defaults::media_user')
      $group          = lookup('defaults::media_group')
      $adminemail     = lookup('defaults::adminemail')

      file { $target:
        ensure  => directory,
        owner   => $owner,
        group   => $group,
        require => Service[ 'sssd' ],
      }
      -> python::pyvenv { $venv: # install dependencies
          ensure     => present,
          version    => 'system',
          systempkgs => true,
          owner      => $owner,
          group      => $group,
          require    => File[ $target ],
        }
        -> python::pip { $type:
            ensure       => 'present',
            pkgname      => $type,
            pip_provider => 'pip',
            virtualenv   => $venv,
            owner        => $owner,
            group        => $group,
            timeout      => 1800,
          }

      file { $configdir:
        ensure => directory,
        owner  => $owner,
        group  => $group,
      }
      $defaults = {
        path    => $target_ini,
        require => File[ $configdir ],
      }
      $default_settings = {
        'rpool' => {
          'frequent' => '4',
          'hourly'   => '24',
          'daily'    => '7',
          'weekly'   => '4',
          'monthly'  => '3',
          'yearly'   => '0',
          'snap'     => 'no',
          'clean'    => 'yes',
        },
        'rpool/ROOT' => {
          'snap' => 'yes',
        },
        'rpool/home' => {
          'snap' => 'yes',
        }
      }
      inifile::create_ini_settings($default_settings + $settings, $defaults)

      cron::job { 'pyznap':
        user        => root,
        minute      => '*/15',
        environment => [ 'PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/sbin:/usr/local/bin"' ],
        command     => '/opt/pyznap/venv/bin/pyznap snap >> /var/log/pyznap.log 2>&1',
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
