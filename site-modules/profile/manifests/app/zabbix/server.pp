# @summary Manage zabbix-server
#
class profile::app::zabbix::server {

  # additional packages needed for ubuntu 16.04 and zabbix 3
  #package { [ 'php-xml', 'php-mbstring', 'php-bcmath' ] : }
  #package { [ 'snmp', 'snmp-builder' ] : }

  class { 'apache': mpm_module => 'prefork', }
  include apache::mod::php

  contain profile::app::db::mysql::server

  class { 'zabbix':
    zabbix_url        => $::facts['networking']['fqdn'],
    database_type     => 'mysql',
    database_name     => 'zabbix',
    database_user     => 'zabbix',
    database_password => hiera('secrets::mysql'),
    manage_resources  => true,
  }

  [
    'template_app_backuppc_active',
    'template_app_easeus_todo_backup_active',
    'template_app_speedtest_active',
    'template_app_xteve_active',
    'template_app_zfs_active',
    'template_module_processes_autodiscovery_active',
  ].each |String $template| {
    zabbix::template { $template:
      templ_source => "puppet:///modules/profile/zabbix/server/templates/${template}.xml",
    }
  }

}
