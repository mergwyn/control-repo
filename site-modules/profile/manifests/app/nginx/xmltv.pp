#
#
class profile::app::nginx::xmltv {
  include profile::app::nginx

  nginx::resource::server { $trusted['hostname']:,
    server_name          => $trusted['certname'],
    listen_port          => 80,
    use_default_location => false,
    locations            => {
      '/xmltv/'      => {
        location_alias => '/srv/media/xmltv/',
        autoindex      => 'off',
      },
      '/favicon.ico' => {
        location_cfg_append => {
          access_log    =>     'off',
          return        => '204',
          log_not_found =>  'off',
        },
      },
    }
  }
}
