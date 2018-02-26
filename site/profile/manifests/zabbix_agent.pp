#

class profile::zabbix_agent {
  class {'zabbix::agent': }

  $etc='/etc/zabbix'
  $dir="$etc/scripts"
  file { [ "$etc", "$dir" ]: ensure => directory, }

  file { "/etc/sudoers.d/zabbix":
    ensure  => present,
    content  => "zabbix ALL=NOPASSWD: /bin/netstat\n",
    mode    => '0440',
  }

  file { "$dir/discovery_disks.perl":
    ensure  => present,
    source  => "puppet:///modules/profile/zabbix_agent/discovery_disks.perl",
    mode    => '0555',
  }
  zabbix::userparameters { 'disk_autodiscovery':
    source => 'puppet:///modules/profile/zabbix_agent/disk_autodiscovery.conf',
  }

  file { "$dir/discovery_processes.sh":
    ensure  => present,
    source  => "puppet:///modules/profile/zabbix_agent/discovery_processes.sh",
    mode    => '0555',
  }
  zabbix::userparameters { 'process_autodiscovery':
    content => "UserParameter=custom.proc.discovery_perl,/etc/zabbix/scripts/discovery_processes.sh\n"
  }

  file { "$dir/discovery_tcp_services.perl":
    ensure  => present,
    source  => "puppet:///modules/profile/zabbix_agent/discovery_tcp_services.perl",
    mode    => '0555',
  }
  zabbix::userparameters { 'service_autodiscovery_tcp':
    content => "UserParameter=custom.services.tcp.discovery_perl,/etc/zabbix/scripts/discovery_tcp_services.perl\n",
  }

  file { "$dir/discovery_udp_services.perl":
    ensure  => present,
    source  => "puppet:///modules/profile/zabbix_agent/discovery_udp_services.perl",
    mode    => '0555',
  }
  zabbix::userparameters { 'service_autodiscovery_udp':
    content => "UserParameter=custom.services.udp.discovery_perl,/etc/zabbix/scripts/discovery_udp_services.perl\n",
  }

  zabbix::userparameters { 'os_version':
    content => "UserParameter=custom.os.version,lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om\n"
  }
}
# vim: sw=2:ai:nu expandtab
