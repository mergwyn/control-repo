#
class profile::backuppc_server {

  package { 'pigz': }

  #TODO: add mounts for srv2
  group { 'backuppc':
    uid        => '125',
  }
  user { 'backuppc':
    groups     => 'backuppc',
    uid        => '118',
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
  #Sshkey <<| tag == "backuppc_sshkeys_${facts['networking']['fqdn']}" |>>
  Sshkey <<| |>>

# vim: sw=2:ai:nu expandtab
