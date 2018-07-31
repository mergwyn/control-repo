#
class profile::backuppc_server {

  package { 'pigz': }

  # this assumes web server is defined and is nginx
  service { 'apache2':
    ensure => 'stopped',
    enable => false,
  }

  # define nginx config
  class { 'nginx':
    nginx_cfg_prepend => {
      include => [ '/etc/nginx/modules-enabled/*.conf' ],
    }
  }

  nginx::resource::server { 'backuppc':
    server_name          => [ $::facts['fqdn'] ],
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

  #TODO: add mounts for srv2
#UUID=87be41fa-af64-4165-b8a4-1d27cba1f349 /srv2	ext4	defaults,user_xattr,acl		0	0
#/srv2/backuppc		/var/lib/backuppc	none	bind,rw				0	0

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

  # Hook into zabbix
  zabbix::userparameters { 'backuppc':
    source => 'puppet:///modules/profile/backuppc/backuppc.conf',
  }
  zabbix::userparameters { 'discovery_backuppc_sudo.pl':
    script  => 'puppet:///modules/profile/backuppc/discovery_backuppc_sudo.pl',
  }
  zabbix::userparameters { 'check_backuppc_sudo.pl':
    script  => 'puppet:///modules/profile/backuppc/check_backuppc_sudo.pl',
  }
}

  # support for backuppc ssh keys
  $topdir = '/var/lib/backuppc'

  # Export backuppc's authorized key to all clients
  # TODO don't rely on facter to obtain the ssh key.
  #if $facts['backuppc_pubkey_rsa'] != undef {
    @@ssh_authorized_key { "backuppc_${facts['networking']['fqdn']}":
      ensure  => present,
      key     => $facts['backuppc_pubkey_rsa'],
      name    => "backuppc_${facts['networking']['fqdn']}",
      user    => 'backuppc',
      options => [
        #'command="~/backuppc.sh"',
        'no-agent-forwarding',
        'no-port-forwarding',
        'no-pty',
        'no-X11-forwarding',
      ],
      type    => 'ssh-rsa',
      tag     => "backuppc_${facts['networking']['fqdn']}",
    }
  #}

  # collect hostkeys
  Sshkey <<| tag == "backuppc_sshkeys_${facts['networking']['fqdn']}" |>>
  #Sshkey <<| |>>

# vim: sw=2:ai:nu expandtab
