#

class profile::zabbix_server {

  # additional packages needed for ubuntu 16.04 and zabbix 3
  package { [ 'php-xml', 'php-mbstring', 'php-bcmath' ] : }
  #package { [ 'snmp', 'snmp-builder' ] : }

  class { 'apache': mpm_module => 'prefork', }
  include apache::mod::php

  include profile::mysql_server

  class { 'zabbix': }

}
# vim: sw=2:ai:nu expandtab
