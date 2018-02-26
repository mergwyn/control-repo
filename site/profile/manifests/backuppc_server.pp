class profile::backuppc_server {
#
  
  zabbix::userparameters { 'backuppc':
    source => "puppet:///modules/profile/backuppc/backuppc.conf",
  }
  zabbix::userparameters { "discovery_backuppc_sudo.pl":
    script  => "puppet:///modules/profile/backuppc/discovery_backuppc_sudo.pl",
  }
  zabbix::userparameters { "check_backuppc_sudo.pl":
    script  => "puppet:///modules/profile/backuppc/check_backuppc_sudo.pl",
  }
}
#
# vim: sw=2:ai:nu expandtab
