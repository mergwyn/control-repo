#
# TODO: move to hiera?

class profile::webmin_generic {
  $adminemail=hiera('unattended_upgrades::email')

  # for 2FA with google
  package { 'libauthen-oath-perl': }

  class { 'webmin':
    #usermin => 'disable',
    require => Package['libauthen-oath-perl'],
  }

  # update config values

  $package_updates_defaults = {
    'path'              => '/etc/webmin/package-updates/config',
    'require'           => 'Package[webmin]',
    'notify'            => 'Service[webmin]',
    'key_val_separator' => '=',
  }

  $package_updates_settings = {
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
