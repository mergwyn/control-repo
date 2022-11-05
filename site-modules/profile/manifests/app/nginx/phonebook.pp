#
#
class profile::app::nginx::phonebook {
  include profile::app::nginx

  nginx::resource::server { $trusted['hostname']:,
    server_name          => [ $trusted['certname'] ],
    listen_port          => 80,
    use_default_location => false,
    locations            => {
      '/phonebook/' => {
        location_alias => '/var/www/html/phonebook/',
        autoindex      => 'off',
      },
    }
  }
}
