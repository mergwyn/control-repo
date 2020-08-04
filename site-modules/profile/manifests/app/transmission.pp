# @summary transmission daemon
#

class profile::app::transmission (
  String $owner   = 'media',
  String $group   = '513',
  String $service = 'transmission-daemon',
  ) {

  class { 'transmission':
    home_dir                   => '/home/media/.config/transmission-daemon',
    umask                      => 2,
    owner                      => $owner,
    group                      => $group,

    download_root              => '/srv/media/torrent/',
    download_dir               => 'complete',
    incomplete_dir             => 'incomplete',
    watch_dir                  => 'watch',

    idle_seeding_limit         => 600,
    idle_seeding_limit_enabled => true,
    ratio_limit                => 1,
    ratio_limit_enabled        => true,
    rpc_enabled                => false,
    rpc_password               => '{9611e36bfc22b97aed5386263ce806ad4ccf1a27qaqXGcAK',
    rpc_username               => '',
    rpc_host_whitelist_enabled => false,
    speed_limit_up             => 250,
    speed_limit_up_enabled     => true,
  }

  systemd::dropin_file { 'transmission-sssd-wait.conf':
    unit    => "${service}.service",
    content => @("EOT"/),
               [Unit]
               After=nss-user-lookup.target
               | EOT
    notify  => Service[$service],
  }
  systemd::dropin_file { 'transmission-user.conf':
    unit    => "${service}.service",
    content => @("EOT"/),
               [Service]
               User=${owner}
               Group=${group}
               | EOT
    notify  => Service[$service],
  }

}
