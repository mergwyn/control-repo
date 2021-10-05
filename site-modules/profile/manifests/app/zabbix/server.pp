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
    'Template App BackupPC by Zabbix agent active',
    'Template App EaseUS ToDo Backup by Zabbix agent active',
    'Template App Puppet by Zabbix agent active',
    'Template App Speedtest by Zabbix agent active',
    'Template App xTeve by Zabbix agent active',
    'Template Module Linux processes by Zabbix agent active',
    'Template OS Linux LXC by Zabbix agent active',
  ].each |String $template| {
    zabbix::template { $template:
      templ_source => "puppet:///modules/profile/zabbix/server/templates/${template}.xml",
    }
  }

}
