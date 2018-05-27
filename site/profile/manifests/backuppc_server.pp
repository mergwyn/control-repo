#
class profile::backuppc_server {

  package { 'pigz': }
  
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

#  if $facts['backuppc_pubkey_rsa'] {
#    # use public key from fact
#    $pubkey_rsa = $facts['backuppc_pubkey_rsa']
#  } else {
#    # fact not yet ready, generate key
#    $pubkey_rsa = undef
#    exec { 'backuppc-ssh-keygen':
#      command => "ssh-keygen -f ${topdir}/.ssh/id_rsa -C 'BackupPC on ${::fqdn}' -N ''",
#      user    => 'backuppc',
#      creates => "${topdir}/.ssh/id_rsa",
#      path    => ['/usr/bin','/bin'],
#      require => [
#          Package['backuppc'],
#          File["${topdir}/.ssh"],
#      ],
#    }
#  }

  # Export backuppc's authorized key for collection by clients
  if $facts['backuppc_pubkey_rsa'] != undef {
    @@ssh_authorized_key { "backuppc_${::fqdn}":
      ensure  => present,
      key     => $pubkey_rsa,
      user    => 'backuppc',
      options => [
        #'command="~/backuppc.sh"',
        'no-agent-forwarding',
        'no-port-forwarding',
        'no-pty',
        'no-X11-forwarding',
      ],
      type    => 'ssh-rsa',
      tag     => "backuppc_${::fqdn}",
    }
  }

  # collect hostkeys
  #Sshkey <<| tag == "backuppc_sshkeys_${facts['networking']['fqdn']}" |>>
  Sshkey <<| |>>

# vim: sw=2:ai:nu expandtab
