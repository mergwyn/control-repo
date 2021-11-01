# @summary install script to backup zabbix
#
class profile::app::zabbix::backup {

  if defined('profile::app::zabbix::agent') {
    include profile::app::zabbix::zapish
    include profile::app::scripts

    $preuser  = hiera('profile::app::backuppc::client::preuser')

    file { "${preuser}/S30zabbix-template-backup":
      ensure  => present,
      mode    => '0555',
      require => Class['profile::app::backuppc::client'],
      content => @("EOT"/),
                 #!/usr/bin/env bash
                 /opt/scripts/bin/zabbix_template_backup
                 | EOT
    }
  }
}
