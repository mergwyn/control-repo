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
    database_password => hiera('secrets::mysql'),
    manage_resources  => true,
    manage_vhost      => false,
  }

  contain profile::app::nginx

  package { [ 'zabbix-nginx-conf' ]:
    require => Class[ 'zabbix' ],
  }

  augeas { 'set_port_and_server':
    context => '/files/etc/zabbix/nginx.conf',
    incl    => '/files/etc/zabbix/nginx.conf',
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
    'Template Module Linux processes by Zabbix agent active',
    'Template OS Linux LXC by Zabbix agent active',
  ].each |String $template| {
    zabbix::template { $template:
      templ_source => "puppet:///modules/profile/zabbix/server/templates/${template}.xml",
      require      => Augeas['set_port_and_server'],
    }
  }


#  include profile::app::nginx
#
#  nginx::resource::server { 'zabbix':
#    server_name => [ $::facts['networking']['fqdn'] ],
#    listen_port => 80,
#    www_root    => '/usr/share/zabbix',
#    locations   => {
#      '/favicon.ico'                        => {
#        server              => 'zabbix',
#        location_cfg_append => { log_not_found => 'off' },
#      },
#
#      '/'                                   => {
#        server              => 'zabbix',
#        location_cfg_append => { try_files => '$uri $uri/ =404' },
#      },
#
#      '/assets'                             => {
#        server     => 'zabbix',
#        access_log => 'off',
#        expires    => '10d',
#      },
#
#      '~ /\.ht'                             => {
#        server => 'zabbix',
#        deny   => 'all',
#      },
#
#      '~ /(api\/|conf[^\.]|include|locale)' => {
#        server => 'zabbix',
#        deny   => 'all',
#        return => 'all',
#      },
#
#      '~ [^/]\.php(/|$)'                    => {
#        server              => 'zabbix',
#        fastcgi_pass        => 'unix:/var/run/php/zabbix.sock',
#        fastcgi_split_path  => '^(.+\.php)(/.+)$',
#        fastcgi_index       => 'index.php',
#        include             => 'fastcgi_params',
#        fastcgi_params      => {
#          'DOCUMENT_ROOT'   => '/usr/share/zabbix',
#          'SCRIPT_FILENAME' => '/usr/share/zabbix$fastcgi_script_name',
#          'PATH_TRANSLATED' => '/usr/share/zabbix$fastcgi_script_name',
#          'QUERY_STRING'    => '$query_string',
#          'REQUEST_METHOD'  => '$request_method',
#          'CONTENT_TYPE'    => '$content_type',
#          'CONTENT_LENGTH'  => '$content_length',
#        },
#        location_cfg_append => {
#          'fastcgi_intercept_errors'     => 'on',
#          'fastcgi_ignore_client_abort'  => 'off',
#          'fastcgi_connect_timeout'      => '60',
#          'fastcgi_send_timeout'         => '180',
#          'fastcgi_read_timeout'         => '180',
#          'fastcgi_buffer_size'          => '128k',
#          'fastcgi_buffers'              => '4 256k',
#          'fastcgi_busy_buffers_size'    => '256k',
#          'fastcgi_temp_file_write_size' => '256k',
#        },
#      },
#    },
#  }


}
