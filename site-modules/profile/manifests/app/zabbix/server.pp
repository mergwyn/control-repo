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
    #zabbix_url        => $::facts['networking']['fqdn'],
    zabbix_url        => lookup('defaults::zabbix_url'),
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

# php setup
  include '::php'
  php::fpm::pool { 'zabbix':
    user                   => 'www-data',
    group                  => 'www-data',
    listen                 => '/var/run/php/zabbix.sock',
    listen_owner           => 'www-data',
    listen_allowed_clients => '127.0.0.1',
    pm                     => dynamic,
    pm_max_children        => 50,
    pm_start_servers       => 5,
    pm_min_spare_servers   => 5,
    pm_max_spare_servers   => 35,
    php_value              => {
      'session.save_handler' => 'files',
      'session.save_path'    => '/var/lib/php/sessions/',
      max_execution_time     => 300,
      memory_limit           => '128M',
      post_max_size          => '16M',
      upload_max_filesize    => '2M',
      max_input_time         => 300,
      max_input_vars         => 10000,
      'date.timezone'        => 'Europe/London',
    }
  }

# nginx setup
  contain profile::app::nginx

  package { [ 'zabbix-nginx-conf' ]: ensure => absent, }

  nginx::resource::server { $trusted['hostname']:
    server_name          => [ $trusted['certname'] ],
    listen_port          => 80,
    www_root             => '/usr/share/zabbix',
    use_default_location => false,
    locations            => {
      '/'                                   => {
        location_cfg_append => { try_files => '$uri $uri/ =404' },
      },
      '/favicon.ico'                        => {
        location_cfg_append => { log_not_found => 'off' },
      },
      '/assets'                             => {
        expires             => '10d',
        location_cfg_append => { access_log => 'off', }
      },
      '~ /\.ht'                             => {
        location_cfg_append => { deny => 'all', }
      },
      '~ /(api\/|conf[^\.]|include|locale)' => {
        location_cfg_append => {
          deny   => 'all',
          return => '404',
        },
      },
      '~ [^/]\.php(/|$)'                    => {
        fastcgi             => 'unix:/var/run/php/zabbix.sock',
        fastcgi_split_path  => '^(.+\.php)(/.+)$',
        fastcgi_index       => 'index.php',
        include             => [ 'fastcgi_params' ],
        fastcgi_param       => {
          'DOCUMENT_ROOT'   => '/usr/share/zabbix',
          'SCRIPT_FILENAME' => '/usr/share/zabbix$fastcgi_script_name',
          'PATH_TRANSLATED' => '/usr/share/zabbix$fastcgi_script_name',
          'QUERY_STRING'    => '$query_string',
          'REQUEST_METHOD'  => '$request_method',
          'CONTENT_TYPE'    => '$content_type',
          'CONTENT_LENGTH'  => '$content_length',
        },
        location_cfg_append => {
          'fastcgi_intercept_errors'     => 'on',
          'fastcgi_ignore_client_abort'  => 'off',
          'fastcgi_connect_timeout'      => '60',
          'fastcgi_send_timeout'         => '180',
          'fastcgi_read_timeout'         => '180',
          'fastcgi_buffer_size'          => '128k',
          'fastcgi_buffers'              => '4 256k',
          'fastcgi_busy_buffers_size'    => '256k',
          'fastcgi_temp_file_write_size' => '256k',
        },
      },
    },
  }

# TODO move to location closer to the functionality that requires the template
# TODO add windows and MacOS
  [
    #'Template App BackupPC by Zabbix agent active',
    #'Template App EaseUS ToDo Backup by Zabbix agent active',
    'Template App Puppet by Zabbix agent active',
    #'Template App Speedtest by Zabbix agent active',
    #'Template App xTeve by Zabbix agent active',
    #'Template App ZFS by Zabbix agent active',
    #'Template Module Linux processes by Zabbix agent active',
    'Template OS Linux LXC by Zabbix agent active',
  ].each |String $template| {
    zabbix::template { $template:
      templ_source => "puppet:///modules/profile/zabbix/server/templates/${template}.xml",
    }
  }

  Class['zabbix::resources::web']
  -> Zabbix_template_host <<| |>>
}
