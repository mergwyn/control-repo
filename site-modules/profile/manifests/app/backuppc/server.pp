#
class profile::app::backuppc::server (
  $uid = 997,
  $gid = 199,
) {

  if $facts['os']['family'] != 'Debian' {
    fail("${title} is only for Debian")
  }

  Class['profile::platform::baseline::debian::ssh'] -> Class['profile::app::backuppc::server']

  include profile::app::scripts

  package { 'pigz': }
  package { 'par2': }
  package { 'libjson-perl': }

  # this assumes web server is defined and is nginx
  service { 'apache2':
    ensure => 'stopped',
    enable => false,
  }
  include profile::app::nginx

  ensure_resource ('nginx::resource::server', $trusted['hostname'], {
    server_name          => [ $trusted['certname'] ],
    listen_port          => 80,
    use_default_location => false,
  } )

  nginx::resource::location { "backuppc_${trusted['hostname']}":
    location            => '/backuppc',
    server              => $trusted['hostname'],
    index_files         => [ '/index.cgi' ],
    location_cfg_append => {
      auth_pam              => '"BackupPC admin"',
      auth_pam_service_name => '"nginx"',
    },
    location_alias      => '/usr/share/backuppc/cgi-bin/',
  }
  nginx::resource::location { "cgi_${trusted['hostname']}":
    location            => '~\.cgi$',
    server              => $trusted['hostname'],
    fastcgi             => 'unix:/var/run/fcgiwrap.socket',
    fastcgi_script      => '/usr/share/backuppc/cgi-bin$fastcgi_script_name',
    fastcgi_params      => '/etc/nginx/fastcgi_params',
    fastcgi_index       => 'BackupPC_Admin',
    location_cfg_append => {
      gzip => 'off',
    },
  }

  group { 'backuppc':
    gid        => $gid,
  }
  user { 'backuppc':
    groups     => 'backuppc',
    uid        => $uid,
    home       => '/var/lib/backuppc',
    comment    => 'BackupPC,,,',
    managehome => false,
    require    => Group['backuppc'],
  }
  User['backuppc']
  -> Class['backuppc::server']

  class { 'backuppc::server':
    backuppc_password          => lookup('secrets::backuppc'),
    gzip_path                  => '/usr/bin/pigz',
    full_age_max               => 370,
    rsync_args_extra           => [ '--recursive', '--one-file-system', '-F' ],
    full_keep_cnt              => [ 4, 0, 12],
    incr_age_max               => 21,
    incr_keep_cnt              => 12,
    backup_zero_files_is_fatal => true,
    cgi_date_format_mmdd       => 1,
    apache_configuration       => false,
    blackout_periods           => [
      {
        hourBegin => 7.0,
        hourEnd   => 22.5,
        weekDays  => [ 1, 2, 3, 4, 5],
      },
      {
        hourBegin => 3,
        hourEnd   => 22.5,
        weekDays  => [ 0, 6],
      },
    ],
  }

#  $topdir = '/var/lib/backuppc'
#  Sshkey <<| tag == "backuppc_sshkeys_${facts['networking']['fqdn']}" |>> {
#      target => "${topdir}/.ssh/known_hosts"
#  }


  # zabbix config
  include sudo
  sudo::conf { 'zabbix-backuppc':
    content => 'zabbix  ALL=(ALL)       NOPASSWD:       /etc/zabbix/scripts/*',
  }

  # Hook into zabbix
  zabbix::userparameters { 'backuppc':
    source => 'puppet:///modules/profile/backuppc/backuppc.conf',
  }
  zabbix::userparameters { 'discovery_backuppc_sudo.pl':
    script     => 'puppet:///modules/profile/backuppc/discovery_backuppc_sudo.pl',
    script_dir => '/etc/zabbix/scripts',
  }
  zabbix::userparameters { 'check_backuppc_sudo.pl':
    script     => 'puppet:///modules/profile/backuppc/check_backuppc_sudo.pl',
    script_dir => '/etc/zabbix/scripts',
  }
  zabbix::userparameters { 'backuppc_info.pl':
    script     => 'puppet:///modules/profile/backuppc/backuppc_info.pl',
    script_dir => '/etc/zabbix/scripts',
  }
}
