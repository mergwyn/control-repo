#
#
class profile::app::nginx {

  # TODO: move to hiera
  include nginx

  if defined('profile::app::zabbix::agent') {
# TODO set up the location needed for this template
    nginx::resource::location { "basic_status_${trusted['hostname']}":
      ensure         => present,
      server         => $trusted['hostname'],
      location       => '/basic_status',
      stub_status    => true,
      location_allow => [ '127.0.0.1', lookup('defaults::cidr') ],
      location_deny  => [ 'all', ],
    }

    profile::app::zabbix::template_host { 'Template App Nginx by Zabbix agent': ensure => absent, }
    profile::app::zabbix::template_host { 'Template App Nginx by HTTP': }
  }

  package { [ 'fcgiwrap' ]: }

}
