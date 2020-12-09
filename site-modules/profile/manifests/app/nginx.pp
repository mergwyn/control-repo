#

class profile::app::nginx {

  # TODO: move to hiera
  include nginx
  package { [ 'fcgiwrap' ]: }

  $service_name = 'nginx.service'
  $service = 'nginx.service'
  # TODO WORKAROUND 1: https://github.com/voxpupuli/puppet-nginx/issues/1372#issuecomment-611736052
  #
  # This implements Workaround 1 for nginx failing to start on boot because /run/nginx
  # doesn't exist. Once that issue has been resolved, we should remove this
  systemd::dropin_file { 'nginx-runtime.conf':
      unit    => $service_name,
      content => @("EOT"/),
                 [Service]
                 RuntimeDirectory=nginx
                 | EOT
  } ~> service { $service_name:
    ensure => 'running',
  }
  # TODO WORKAROUND 2: Make sure puppet keeps the file mode to 0700 for /run/nginx
  File <| title == '/run/nginx/client_body_temp' or title == '/run/nginx/proxy_temp' |> {
    mode => '0700',
  }
}
