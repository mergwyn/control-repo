#

class profile::mysql::server {

  include mysql::server

  $defaults = {
    'path'         => '/etc/mysql/mysql.conf.d/overrides.cnf',
    'indent_width' => '0',
    'notify'       => Service['mysqld'],
  }
  $overrides = {
    'mysqld' => {
      '# MyISAM '                      => '#',
      'key-buffer-size'                => '32M',
      'myisam-recover-options'         => 'FORCE,BACKUP',
      # SAFETY #
      'max-allowed-packet'             => '16M',
      'max-connect-errors'             => '1000000',
      # BINARY LOGGING #
      'log_bin'                        => '/var/lib/mysql/log/mysql-bin.log',
      'expire-logs-days'               => '14',
      'sync-binlog'                    => '1',
      # CACHES AND LIMITS #
      'tmp-table-size'                 => '32M',
      'max-heap-table-size'            => '32M',
      'query-cache-type'               => '0',
      'query-cache-size'               => '0',
      'max-connections'                => '500',
      'thread-cache-size'              => '50',
      'open-files-limit'               => '65535',
      'table-definition-cache'         => '1024',
      'table-open-cache'               => '2048',
      # INNODB #
      #'innodb-flush-method' => 'O_DIRECT',
      'innodb-log-files-in-group'      => '2',
      'innodb-log-file-size'           => '128M',
      'innodb-flush-log-at-trx-commit' => '1',
      'innodb-file-per-table'          => '1',
      'innodb-buffer-pool-size'        => '2G',
      'innodb_buffer_pool_size'        => '1300M',
      'server-id'                      => '1',
      #'setting1'  => 'value1',
      #'settings2' => {
      #  'ensure' => 'absent'
      #}
    }
  }
  create_ini_settings($overrides, $defaults)

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
