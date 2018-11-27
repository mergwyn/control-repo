#

class profile::web::munki {
  include profile::web::nginx

  nginx::resource::server { 'munki_repo':,
    server_name          => [ $::facts['networking']['fqdn'] ],
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
