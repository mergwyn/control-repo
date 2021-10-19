#
#
class profile::app::nginx::webdav{
  include profile::app::nginx

  if ! defined(nginx::resource::server[$trusted['hostname']]) {
    nginx::resource::server { $trusted['hostname']:
      listen_port          => 80,
      use_default_location => false,
    }
  }
  nginx::resource::location { "webdav_${trusted['hostname']}":
    location            => '/webdav',
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
  }
}

