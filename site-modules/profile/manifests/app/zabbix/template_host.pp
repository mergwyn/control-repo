# @summary link a template to a host using the zabbix api
#
define profile::app::zabbix::template_host {
  @@zabbix_template_host { "${title}@${facts['hostname']}": ensure => 'present', }
}
