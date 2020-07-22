#

class profile::web::nginx {

  # TODO: move to hiera
  include nginx
  package { [ 'fcgiwrap' ]: }

  $service_name = 'nginx.service'
  $service = 'nginx.service'
  systemd::dropin_file { 'nginx-runtime.conf':
      unit    => $service_name,
      content => @("EOT"/),
                 [Service]
                 RuntimeDirectory=nginx
                 | EOT
  } ~> service { $service_name:
    ensure => 'running',
  }

}

