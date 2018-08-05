#

class profile::web_server {
  include nginx
  package { [ 'fcgiwrap' ]: }

  # define nginx config
  class { 'nginx':
    nginx_cfg_prepend => {
      include => [ '/etc/nginx/modules-enabled/*.conf' ],
    }
  }

  nginx::resource::server { 'webdav':
    server_name          => [ $::facts['fqdn'] ],
    listen_port          => 80,
    use_default_location => false,
    locations            => {
      '/webdav' => {
        server              => 'webdav',
        autoindex           => 'on',
        index_files         => [ '/index.cgi' ],
        location_alias      => '/srv/webdav',
        location_cfg_append => {
          auth_pam              => '"Restricted area"',
          auth_pam_service_name => '"nginx"',
          dav_methods           => 'PUT DELETE MKCOL COPY MOVE',
          dav_ext_methods       => 'PROPFIND OPTIONS',
          dav_access            => 'group:rw all:r',
          create_full_put_path  => 'on',
        },
      },
    },
  }
  nginx::resource::server { 'munki_repo':,
    server_name          => [ $::facts['fqdn'] ],
    listen_port          => 80,
    use_default_location => false,
    locations            => {
      '/munki_repo/' => {
        server              => 'munki_repo',
        location_alias      => '/usr/share/nginx/html/munki-repo/',
        autoindex           => 'off',
        location_cfg_append => {
          auth_pam              => '"Restricted area"',
          auth_pam_service_name => '"nginx"',
        }
      }
    }
  }
}

#
# vim:  sw=2:ai:nu expandtab
