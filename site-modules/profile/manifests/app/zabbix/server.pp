# @summary Manage zabbix-server
#
class profile::app::zabbix::server {

  # additional packages needed for ubuntu 16.04 and zabbix 3
  #package { [ 'php-xml', 'php-mbstring', 'php-bcmath' ] : }
  #package { [ 'snmp', 'snmp-builder' ] : }

# For zabbixapi
  package { [ 'build-essential' ] : }

  contain profile::app::db::mysql::server

  class { 'zabbix':
    zabbix_url        => $::facts['networking']['fqdn'],
    zabbix_version    => lookup('defaults::zabbix_version'),
    zabbix_timezone   => 'Europe/London',
    database_type     => 'mysql',
    database_name     => 'zabbix',
    database_user     => 'zabbix',
    database_password => lookup('secrets::mysql'),
    zabbix_api_pass   => lookup('secrets::mysql'),
    manage_resources  => true,
    manage_vhost      => false,
  }

  contain profile::app::nginx

  package { [ 'zabbix-nginx-conf' ]:
    require => Class[ 'zabbix' ],
  }

  augeas { 'set_port_and_server':
    context => '/files/etc/zabbix/nginx.conf',
    incl    => '/etc/zabbix/nginx.conf',
    lens    => 'Nginx.lns',
    #onlyif  => "get $key != '$value'",
    #changes => "set $key '$value'",
    notify  => Service[ 'nginx' ],
    require => Package[ 'zabbix-nginx-conf' ],
    changes => [
      'set server/listen 80',
      "set server/server_name ${trusted['certname']}",
    ],
  }


# TODO move to location closer to the functionality that requires the template
  [
    'Template App BackupPC by Zabbix agent active',
    'Template App EaseUS ToDo Backup by Zabbix agent active',
    'Template App Puppet by Zabbix agent active',
    'Template App Speedtest by Zabbix agent active',
    'Template App xTeve by Zabbix agent active',
    'Template App ZFS by Zabbix agent active',
    'Template Module Linux processes by Zabbix agent active',
    'Template OS Linux LXC by Zabbix agent active',
  ].each |String $template| {
    zabbix::template { $template:
      templ_source => "puppet:///modules/profile/zabbix/server/templates/${template}.xml",
      require      => Augeas['set_port_and_server'],
    }
  }

}
