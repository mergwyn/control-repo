#

class profile::app::db::mysql::server {

  include mysql::server

  $defaults = {
    'path'         => '/etc/mysql/mysql.conf.d/overrides.cnf',
    'indent_width' => '0',
    'notify'       => Service['mysqld'],
  }
  $overrides = {
    'mysqld' => {
      # MyISAM #
      'key_buffer_size'                => '32M',
      'myisam_recover_options'         => 'FORCE,BACKUP',
      # SAFETY #
      'max_allowed_packet'             => '16M',
      'max_connect_errors'             => '1000000',
      # BINARY LOGGING #
      'log_bin'                        => '/var/lib/mysql/log/mysql_bin.log',
      'expire_logs_days'               => '14',
      'sync_binlog'                    => '1',
      # CACHES AND LIMITS #
      'tmp_table_size'                 => '32M',
      'max_heap_table_size'            => '32M',
      'query_cache_type'               => '0',
      'query_cache_size'               => '0',
      'max_connections'                => '50',
      'thread_cache_size'              => '50',
      'open_files_limit'               => '65535',
      'table_definition_cache'         => '1024',
      'table_open_cache'               => '2048',
      # INNODB #
      #'innodb_flush_method' => 'O_DIRECT',
      'innodb_log_files_in_group'      => '3',
      'innodb_log_file_size'           => '128M',
      'innodb_flush_log_at_trx_commit' => '1',
      'innodb_file_per_table'          => '1',
      'innodb_buffer_pool_size'        => '1792M',
      'innodb_buffer_pool_instances'   => '1',
      'server_id'                      => '1',
      #'setting1'  => 'value1',
      #'settings2' => {
      #  'ensure' => 'absent'
      #}
    },
  }
  create_ini_settings($overrides, $defaults)

  $scripts  = hiera('profile::backuppc::client::scripts')
  $preuser  = hiera('profile::backuppc::client::preuser')

  file { "${preuser}/S20mysql-backup":
    ensure  => present,
    source  => 'puppet:///modules/profile/backuppc/S20mysql-backup',
    mode    => '0555',
    require => Class['profile::backuppc::client'],
  }

  file { "${scripts}/S20mysql-backup-password":
    ensure  => present,
    content => sprintf("PASSWORD=%s\n",hiera('secrets::mysql')),
    mode    => '0555',
    require => Class['profile::backuppc::client'],
  }

  zabbix::userparameters { 'template_db_mysql':
    source  => 'puppet:///modules/profile/zabbix_agent/template_db_mysql.conf',
    require => Class['profile::zabbix::agent'],
  }
  file {'/var/lib/zabbix/.my.cnf':
    content => sprintf("[client]\nuser=zbx_monitor\npassword=%s\n",hiera('secrets::mysql')),
    mode    => '0555',
    require => Class['profile::zabbix::agent'],
  }
}
