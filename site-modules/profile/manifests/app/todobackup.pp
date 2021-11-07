# @summary Install and configure EaseUS ToDo backup
#
#
class profile::app::todobackup () {
  if $facts['os']['family'] != 'Windows' {
    fail("${name} can only be called on ${facts['os']['family']}")
  }

  # TODO workout why this install fails
  #package {'todobackup': }

  if defined('profile::app::zabbix::agent') {
    profile::app::zabbix::template_host { 'Template App EaseUS ToDo Backup by Zabbix agent active': }
  }

}
