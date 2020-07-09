#

class profile::zabbix::server {

  # additional packages needed for ubuntu 16.04 and zabbix 3
  #package { [ 'php-xml', 'php-mbstring', 'php-bcmath' ] : }
  #package { [ 'snmp', 'snmp-builder' ] : }

  #class { 'apache': mpm_module => 'prefork', }
  #include apache::mod::php

  include profile::app::db::mysql::server
  package { [ 'zabbix-server-mysql', 'zabbix-nginx-conf' ] : }

  #class { 'zabbix': }

}
