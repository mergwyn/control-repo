# @summary Manage SQL Server
#
# @param logdir
#   Location of binary logs
#
class profile::app::db::mysql::server (
  Stdlib::Absolutepath $logdir = '/var/lib/mysql/log',
  String $zabbix_version       = lookup('defaults::zabbix_version'),
){


  class { 'mysql::server':
    manage_config_file => false,
  }

  file { $logdir:
    ensure => directory,
    owner  => 'mysql',
    group  => 'mysql',
  }

  $defaults = {
    'path'         => '/etc/mysql/mysql.conf.d/overrides.cnf',
    'indent_width' => '0',
    notify         => Service['mysqld'],
    require        => File[$logdir],
  }
  $overrides = {
    'mysqld' => {
      # MyISAM #
      #'key_buffer_size'                => '32M',
      'key_buffer_size'                => '8M',
      'myisam_recover_options'         => 'FORCE,BACKUP',
      # SAFETY #
      'max_allowed_packet'             => '16M',
      'max_connect_errors'             => '1000000',
      # BINARY LOGGING #
      #'log_bin'                        => "${logdir}/mysql_bin.log",
      #'binlog_expire_logs_seconds'     => '1209600', # 14 days
      #'sync_binlog'                    => '1',
      # CACHES AND LIMITS #
      'tmp_table_size'                 => '32M',
      'max_heap_table_size'            => '32M',
      'max_connections'                => '50',
      'thread_cache_size'              => '50',
      'open_files_limit'               => '1000',
      'table_definition_cache'         => '1024',
      'table_open_cache'               => '2048',
      # INNODB #
      #'innodb_flush_method' => 'O_DIRECT',
      'join_buffer_size'               => '4M',
      'innodb_flush_log_at_trx_commit' => '1',
      'innodb_file_per_table'          => '1',
      'innodb_buffer_pool_size'        => '1800M',
      'innodb_buffer_pool_instances'   => '1',
      'server_id'                      => '1',
      # Tuning
      'performance_schema'             => 'off',
    },
  }
  create_ini_settings($overrides, $defaults)

  $scripts  = hiera('profile::app::backuppc::client::scripts')
  $preuser  = hiera('profile::app::backuppc::client::preuser')

  if defined('profile::app::backuppc::client') {
    file { "${preuser}/S20mysql-backup":
      ensure  => present,
      source  => 'puppet:///modules/profile/backuppc/S20mysql-backup',
      mode    => '0555',
      require => Class['profile::app::backuppc::client'],
    }

    file { "${scripts}/S20mysql-backup-password":
      ensure  => present,
      content => sprintf("PASSWORD=%s\n",hiera('secrets::mysql')),
      mode    => '0555',
      require => Class['profile::app::backuppc::client'],
    }
  }

# If Zabbix is about, setup up monitoring
  if defined('profile::app::zabbix::agent') {
    $conf     = 'template_db_mysql.conf'

    profile::app::zabbix::template_host { 'Template DB MySQL by Zabbix agent': }

    # Agent configuration
    zabbix::userparameters { $conf:
      require => Class['profile::app::zabbix::agent'],
      source  => "puppet:///modules/profile/zabbix/server/templates/${conf}"
    }

    $user     = 'zbx_monitor'
    $password = lookup('secrets::mysql')

    mysql::db { $user:
      user     => $user,
      password => $password,
      dbname   => '*',
      host     => 'localhost',
      grant    => [ 'REPLICATION CLIENT', 'PROCESS', 'SHOW DATABASES', 'SHOW VIEW' ],
# TODO workaround for utf8
      charset  => 'utf8mb3',
    }

    file {'/var/lib/zabbix/': ensure => directory }
# TODO change to heredoc
    file {'/var/lib/zabbix/.my.cnf':
      content => sprintf("[client]\nuser=%s\npassword=%s\n",$user, $password),
      mode    => '0555',
    }
  }
}
