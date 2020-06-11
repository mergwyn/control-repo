#

class profile::service::webmin {
  $adminemail = lookup('unattended_upgrades::email')

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
    value             => "webmin@${::fqdn}",
    path              => '/etc/webmin/mailboxes/config',
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
  file { '/etc/webmin/package-updates/update.pl':
    ensure  => present,
    mode    => '0755',
    source  => 'puppet:///modules/profile/webmin/update.pl',
    require => File['/etc/webmin/package-updates'],
  }

}
