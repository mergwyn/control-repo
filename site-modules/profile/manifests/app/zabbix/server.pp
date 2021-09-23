#

class profile::app::zabbix::server {

  # additional packages needed for ubuntu 16.04 and zabbix 3
  #package { [ 'php-xml', 'php-mbstring', 'php-bcmath' ] : }
  #package { [ 'snmp', 'snmp-builder' ] : }

  #class { 'apache': mpm_module => 'prefork', }
  #include apache::mod::php


  class { 'zabbix':
    zabbix_url    => $::facts['networking']['fqdn'],
    database_type => 'mysql',
  }

  include profile::app::db::mysql::server

}
