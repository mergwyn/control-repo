#
# TODO: use inifiles for config rather that augeas

class profile::mysql::server {

  class { 'mysql::server': }

  file { '/var/lib/mysql/log':
    ensure => directory,
    owner  => 'mysql',
    group  => 'mysql',
  }

  augeas { 'mysqld.cnf':
    lens    => 'MySQL.lns',
    incl    => '/etc/mysql/mysql.conf.d/mysqld.cnf',
    context => '/files/etc/mysql/mysql.conf.d/mysqld.cnf',
    notify  => Class['mysql::server::service'],
    changes => [
      "set target[.='mysqld']/innodb_buffer_pool_instances 1",
      "set target[.='mysqld']/innodb_buffer_pool_size 1G",
      "set target[.='mysqld']/innodb_flush_log_at_trx_commit 0",
      "set target[.='mysqld']/innodb_log_file_size 128M",
      "set target[.='mysqld']/log_bin /var/lib/mysql/log/mysql-bin.log",
      "set target[.='mysqld']/query_cache_size 0",
      "set target[.='mysqld']/query_cache_type 0",
      "set target[.='mysqld']/server-id 1",
    ]
  }

  $scripts=hiera('profile::backuppc::scripts')
  $preuser=hiera('profile::backuppc::preuser')
  file { "${preuser}/S20mysql-backup":
    ensure  => present,
    source  => 'puppet:///modules/profile/backuppc/S20mysql-backup',
    mode    => '0555',
    require => Class['profile::backuppc::client'],
  }

  file { "${scripts}/S20mysql-backup-password":
    ensure  => present,
    content => sprintf("PASSWORD=%s\n",hiera('passwords::mysql')),
    mode    => '0555',
    require => Class['profile::backuppc::client'],
  }

}
# vim: sw=2:ai:nu expandtab
