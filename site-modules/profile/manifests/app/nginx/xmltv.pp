#
#
class profile::app::nginx::xmltv {
  include profile::app::nginx

  nginx::resource::server { 'xmltv':,
    server_name          => [ $::facts['networking']['fqdn'] ],
    listen_port          => 80,
    use_default_location => false,
    locations            => {
      '/xmltv/'       => {
        server         => 'xmltv',
        location_alias => '/srv/media/xmltv/',
        autoindex      => 'off',
      },
      '/favicon.ico'  => {
        location_cfg_append => {
          access_log    =>     'off',
          return        => '204',
          log_not_found =>  'off',
        },
      },
      '/basic_status' => {
        stub_status => true,
      },

    }
  }
}
