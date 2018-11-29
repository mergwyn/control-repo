#
# TODO: move to hiera?

class profile::webmin_generic {
  $adminemail=hiera('unattended_upgrades::email')

  exec { 'apt_show_versions_clean':
    command   => 'apt-get purge -y apt-show-versions',
    path      => ['/usr/bin', '/sbin', '/bin'],
    unless   => 'test -f /opt/webmin_apt_ppa_install',
    logoutput => 'on_failure',
  } 
  # for 2FA with google
  package { 'libauthen-oath-perl': }

  class { 'webmin':
    #usermin => 'disable',
    require => [ 
      Package['libauthen-oath-perl'],
      Exec['apt_show_versions_clean'],
    ],
  }

  # update config values

  $package_updates_defaults = {
    'path'              => '/etc/webmin/package-updates/config',
    'require'           => 'Package[webmin]',
    'notify'            => 'Service[webmin]',
    'key_val_separator' => '=',
  }

  $package_updates_settings = {
    'require'             => Package['webmin'],
    '' => {
      'sched_email'     => "$adminemail",
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

}
# vim: sw=2:ai:nu expandtab
