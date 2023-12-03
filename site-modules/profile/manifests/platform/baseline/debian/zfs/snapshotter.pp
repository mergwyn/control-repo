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

      python::pip { $type:
        ensure       => 'present',
        pkgname      => $type,
        pip_provider => 'pip3',
        virtualenv   => $venv,
        owner        => $owner,
        group        => $group,
        timeout      => 1800
      }

      file { $configdir:
        ensure => directory,
        owner  => $owner,
        group  => $group,
      }
      $defaults = {
        path    => $target_ini,
        require => File[ $configdir ],
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
      inifile::create_ini_settings($settings, $defaults)

      package { 'zfs-auto-snapshot': ensure => absent }
    }


    'zfs-auto-snapshot': {
      package { 'zfs-auto-snapshot': }
    }
    default: {
    }
  }
}
