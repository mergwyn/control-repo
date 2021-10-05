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
      'key_buffer_size'                => '32M',
      'myisam_recover_options'         => 'FORCE,BACKUP',
      # SAFETY #
      'max_allowed_packet'             => '16M',
      'max_connect_errors'             => '1000000',
      # BINARY LOGGING #
      'log_bin'                        => "${logdir}/mysql_bin.log",
      'expire_logs_days'               => '14',
      'sync_binlog'                    => '1',
      # CACHES AND LIMITS #
      'tmp_table_size'                 => '32M',
      'max_heap_table_size'            => '32M',
#      'query_cache_type'               => '0',
#      'query_cache_size'               => '0',
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
    },
  }
  create_ini_settings($overrides, $defaults)

  $scripts  = hiera('profile::app::backuppc::client::scripts')
  $preuser  = hiera('profile::app::backuppc::client::preuser')

  if defined(Class[profile::app::backuppc::client]) {
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
  if defined(Class[profile::app::zabbix::agent]) {
    $template = 'Template DB MySQL by Zabbix agent'
    $conf     = 'template_db_mysql.conf'

    # This gets created on the server
    zabbix::template { $template:
      templ_source => "puppet:///modules/profile/zabbix/server/templates/${template}_agent.xml",
    }

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
    }

    file {'/var/lib/zabbix/': ensure => directory }
# TODO change to heredoc
    file {'/var/lib/zabbix/.my.cnf':
      content => sprintf("[client]\nuser=%s\npassword=%s\n",$user, $password),
      mode    => '0555',
    }
  }
}
