# @summary webmin settings
#
# $param install install or deinstall webmin
#
class profile::app::webmin(
  Boolean $install = false,
) {

  if $facts['os']['family'] != 'Debian' {
    fail("${title} is only for Debian")
  }

  if $install {
    $adminemail = lookup('defaults::adminemail')

    exec { 'apt_show_versions_clean':
      command   => 'apt-get purge -y apt-show-versions',
      path      => ['/usr/bin', '/sbin', '/bin'],
      unless    => 'test -f /opt/webmin_apt_ppa_install',
      logoutput => 'on_failure',
    }
    # for 2FA with google
    package { 'libauthen-oath-perl': }

    include webmin

    # update config values

    $package_updates_defaults = {
      'path'              => '/etc/webmin/package-updates/config',
      'require'           => 'Package[webmin]',
      'notify'            => 'Service[webmin]',
      'key_val_separator' => '=',
    }

    $package_updates_settings = {
      '' => {
        'sched_email'     => $adminemail,
        'update_multiple' => '1',
        'sched_action'    => '0',
        'cache_time'      => '6',
      }
    }
    create_ini_settings($package_updates_settings, $package_updates_defaults)

    ini_setting { 'webmin_from':
      setting           => 'webmin_from',
      key_val_separator => '=',
      value             => "webmin@${trusted['certname']}",
      path              => '/etc/webmin/mailboxes/config',
      require           => Package['webmin'],
      notify            => Service['webmin'],
    }

    ini_setting { 'shell_path':
      setting           => 'path',
      key_val_separator => '=',
      value             => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/snap/bin:/opt/puppetlabs/bin',
      path              => '/etc/webmin/config',
      require           => Package['webmin'],
      notify            => Service['webmin'],
    }

    file { '/etc/webmin/package-updates':
      ensure  => directory,
      require => Package['webmin'],
    }
    file { '/etc/webmin/package-updates/config':
      ensure  => present,
      mode    => '0600',
      source  => 'puppet:///modules/profile/webmin/config',
      require => File['/etc/webmin/package-updates'],
    }
  }
  else {
    $purgelist = [ 'webmin', 'libauthen-oath-perl' ]
    package { $purgelist: ensure => purged }
  }
}