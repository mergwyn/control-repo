# @summary link a template to a host using the zabbix api
#
define profile::app::zabbix::template_host (
  $ensure = present,
) {
  @@zabbix_template_host { "${name}@${trusted['certname']}":
    ensure => $ensure,
  }
}
