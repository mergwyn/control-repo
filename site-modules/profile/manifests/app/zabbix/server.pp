# @summary Manage zabbix-server
#
class profile::app::zabbix::server {

  # additional packages needed for ubuntu 16.04 and zabbix 3
  #package { [ 'php-xml', 'php-mbstring', 'php-bcmath' ] : }
  #package { [ 'snmp', 'snmp-builder' ] : }

# For zabbixapi
  package { [ 'build-essential' ] : }

  class { 'apache': mpm_module => 'prefork', }
  include apache::mod::php

  contain profile::app::db::mysql::server

# TODO use zabbix::server and setup nginx manually
  class { 'zabbix':
    zabbix_url        => $::facts['networking']['fqdn'],
    database_type     => 'mysql',
    database_name     => 'zabbix',
    database_user     => 'zabbix',
    database_password => hiera('secrets::mysql'),
    manage_resources  => true,
  }

  [
    'template_app_backuppc_by_zabbix_agent_active',
    'template_app_easeus_todo_backup_by_zabbix_agent_active',
    'template_app_puppet_by_zabbix_agent_active',
    'template_app_speedtest_by_zabbix_agent_active',
    'template_app_xteve_by_zabbix_agent_active',
    'template_module_linux_processes_by_zabbix_agent_active',
    'template_os_linux_lxc_by_zabbix_agent_active',
  ].each |String $template| {
    zabbix::template { $template:
      templ_source => "puppet:///modules/profile/zabbix/server/templates/${template}.xml",
    }
  }

}
