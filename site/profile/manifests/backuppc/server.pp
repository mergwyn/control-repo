#
class profile::backuppc::server {

  include profile::scripts

  package { 'pigz': }
  package { 'libjson-perl': }

  # this assumes web server is defined and is nginx
  service { 'apache2':
    ensure => 'stopped',
    enable => false,
  }
  include profile::web::nginx

  nginx::resource::server { 'backuppc':
    server_name          => [ $::facts['networking']['fqdn'] ],
    listen_port          => 80,
    use_default_location => false,
    locations            => {
      '/backuppc' => {
        server              => 'backuppc',
        index_files         => [ '/index.cgi' ],
        location_cfg_append => {
          auth_pam              => '"BackupPC admin"',
          auth_pam_service_name => '"nginx"',
        },
        location_alias      => '/usr/share/backuppc/cgi-bin/',
      },
      'cgi'       => {
        server              => 'backuppc',
        location            => '~\.cgi$',
        fastcgi             => 'unix:/var/run/fcgiwrap.socket',
        fastcgi_script      => '/usr/share/backuppc/cgi-bin$fastcgi_script_name',
        fastcgi_params      => '/etc/nginx/fastcgi_params',
        fastcgi_index       => 'BackupPC_Admin',
        location_cfg_append => {
          gzip => 'off',
        },
      },
    },
  }

  mount { 'srv2':
    ensure  => 'mounted',
    name    => '/srv2',
    device  => 'UUID=87be41fa-af64-4165-b8a4-1d27cba1f349',
    fstype  => 'ext4',
    options => 'defaults,user_xattr,acl',
  }

  mount { 'backuppc':
    ensure  => 'mounted',
    name    => '/var/lib/backuppc',
    device  => '/srv2/backuppc',
    fstype  => 'none',
    options => 'bind,rw',
    require => Mount['srv2'],
  }

  group { 'backuppc':
    gid        => '127',
  }
  user { 'backuppc':
    groups     => 'backuppc',
    uid        => '118',
    home       => '/var/lib/backuppc',
    comment    => 'BackupPC,,,',
    managehome => false,
  }

  include backuppc::server

  $topdir = '/var/lib/backuppc'
  #Sshkey <<| tag == "backuppc_sshkeys_${facts['networking']['fqdn']}" |>> {
  Sshkey <<| tag == 'backuppc_sshkeys_foxtrot.theclarkhome.com' |>> {
      #target => "${topdir}/.ssh/known_hosts"
      target => '/tmp/known_hosts'
  }


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

# vim: sw=2:ai:nu expandtab
