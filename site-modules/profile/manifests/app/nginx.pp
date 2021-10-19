#
#
class profile::app::nginx {

  # TODO: move to hiera
  include nginx

  if defined('profile::app::zabbix::agent') {
# TODO set up the location needed for this template
    nginx::resource::location { "basic_status_${facts['hostname']}":
      ensure         => present,
      server         => $trusted['hostname'],
      location       => '/basic_status',
      stub_status    => true,
      location_allow => [ lookup('defaults::cidr') ],
      location_deny  => [ 'all', ],
    }

    profile::app::zabbix::template_host { 'Template App Nginx by Zabbix agent': }
  }

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
