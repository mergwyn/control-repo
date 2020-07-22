#

class profile::web::nginx {

  # TODO: move to hiera
  include nginx
  package { [ 'fcgiwrap' ]: }

  $service_name = 'nginx.service'
  systemd::unit_file { $service_name:
    content => "[Service]\nRuntimeDirectory=nginx\n"
  }
  ~> service { $service_name:
    ensure => 'running',
  }

}

