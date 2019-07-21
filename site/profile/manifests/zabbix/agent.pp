#

class profile::zabbix::agent {
  case $facts['os']['name'] {
    'Ubuntu': {
      include zabbix::agent
      package {'zabbix-sender': }

      $etc='/etc/zabbix'
      $dir="${etc}/scripts"
      file { [ $etc, $dir ]: ensure => directory, }

      sudo::conf { 'zabbix':
        content => 'zabbix  ALL=NOPASSWD: /bin/netstat',
      }

      zabbix::userparameters { 'discovery_disks.perl':
        script     => 'puppet:///modules/profile/zabbix_agent/discovery_disks.perl',
        script_dir => $dir,
      }
      zabbix::userparameters { 'disk_autodiscovery':
        source => 'puppet:///modules/profile/zabbix_agent/disk_autodiscovery.conf',
      }

      zabbix::userparameters { 'discovery_processes.sh':
        script     => 'puppet:///modules/profile/zabbix_agent/discovery_processes.sh',
        script_dir => $dir,
      }
      zabbix::userparameters { 'process_autodiscovery':
        content => "UserParameter=custom.proc.discovery_perl,${dir}/discovery_processes.sh\n"
      }

      zabbix::userparameters { 'discovery_tcp_services.perl':
        script     => 'puppet:///modules/profile/zabbix_agent/discovery_tcp_services.perl',
        script_dir => $dir,
      }
      zabbix::userparameters { 'service_autodiscovery_tcp':
        content => "UserParameter=custom.services.tcp.discovery_perl,${dir}/discovery_tcp_services.perl\n",
      }

      zabbix::userparameters { 'discovery_udp_services.perl':
        script     => 'puppet:///modules/profile/zabbix_agent/discovery_udp_services.perl',
        script_dir => $dir,
      }
      zabbix::userparameters { 'service_autodiscovery_udp':
        content => "UserParameter=custom.services.udp.discovery_perl,${dir}/discovery_udp_services.perl\n",
      }

      zabbix::userparameters { 'os_version':
        content => "UserParameter=custom.os.version,lsb_release -ds 2>/dev/null || cat /etc/*release 2>/dev/null | head -n1 || uname -om\n"
      }
    }
    'windows': {
      service {'Zabbix Agent':
        ensure  => 'running',
        enable  => true,
        require => Package['zabbix-agent'],
      }
      $defaults = {
        'path'         => 'c:\\ProgramData\\zabbix\\zabbix_agentd.conf',
        'indent_width' => '0',
        'notify'       => Service['Zabbix Agent'],
        require        => Package['zabbix-agent'],
        section        => '',
      }
      $overrides = {
        '' => {
          'Server'       => lookup('zabbix::agent::server'),
          'ServerActive' => lookup('zabbix::agent::serveractive'),
          'Hostname'     => lookup('zabbix::agent::hostname'),
        }
      }
      create_ini_settings($overrides, $defaults)

    }
    default: {}
  }
}
# vim: sw=2:ai:nu expandtab
