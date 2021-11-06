# @summary Installa nd confgure zabbix agent
class profile::app::zabbix::agent (
  $server         = 'zulu',
  $zabbix_version = lookup('defaults::zabbix_version'),
) {

  $serverstring = $server ? {
    $trusted['hostname'] => 'localhost',
    default              => "${server}.${trusted['domain']}",
  }
  $hostmetadata = ":kernel=${facts['kernel']}:virtual=${facts['virtual']}"

# TODO consider moving this to hiera
  case $facts['virtual'] {
    'lxc': {
      $macros =  [
        { '{$VFS.DEV.DEVNAME.MATCHES}' => '^\s$', }, # Only /
        { '{$VFS.FS.FSNAME.MATCHES}'   => '^/$', },  # Disable all
      ]

    }
    default: {
      $macros = []
    }
  }

  case $facts['os']['name'] {
    'Ubuntu': {

      class { 'zabbix::agent':
        zabbix_version       => $zabbix_version,
        hostname             => $trusted['certname'],
        hostinterface        => $trusted['certname'],
        server               => $serverstring,
        serveractive         => $serverstring,
        enableremotecommands => '1',
        zabbix_package_state => 'latest',
        hostmetadata         => $hostmetadata,
        manage_resources     => true,
# TODO consider picking templates and macros from hiera
        zbx_templates        => [ 'Template OS Linux by Zabbix agent active' ],
        zbx_macros           => $macros,
      }

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
          'Hostname'     => $trusted['certname'],
          'Server'       => $serverstring,
          'ServerActive' => $serverstring,
          'HostMetadata' => $hostmetadata,
        }
      }
      create_ini_settings($overrides, $defaults)

    }
    default: {}
  }
}
