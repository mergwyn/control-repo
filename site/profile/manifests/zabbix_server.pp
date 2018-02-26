#
# TODO: use inifiles for config rather that augeas

class profile::zabbix_server {

  # additional packages needed for ubuntu 16.04 and zabbix 3
  package { [ 'php-xml', 'php-mbstring', 'php-bcmath' ] : }
  #package { [ 'snmp', 'snmp-builder' ] : }

  class { 'apache': mpm_module => 'prefork', }
  include apache::mod::php

  class { 'mysql::server': }

  file { '/var/lib/mysql/log':
    ensure => directory,
    owner  => 'mysql',
    group  => 'mysql',
  }

  augeas { 'mysqld.cnf':
    lens => "MySQL.lns",
    incl => '/etc/mysql/mysql.conf.d/mysqld.cnf',
    context => '/files/etc/mysql/mysql.conf.d/mysqld.cnf',
    notify => Class['mysql::server::service'],
    changes => [ 
      "set target[.='mysqld']/log_bin /var/lib/mysql/log/mysql-bin.log",
      "set target[.='mysqld']/server-id 1",
    ] 
  }

  
  class { 'zabbix': }

}
# vim: sw=2:ai:nu expandtab
