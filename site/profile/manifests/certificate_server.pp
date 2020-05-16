#

class profile::certificate_server (
  Array[Stdlib::Fqdn] $domains = []
) {

  include letsencrypt

  letsencrypt::certonly { $trusted['certname']:
    plugin               => 'nginx',
    domains              => $domains,
    manage_cron          => true,
    cron_before_command  => 'service nginx stop',
    cron_success_command => '/bin/systemctl reload nginx.service',
    suppress_cron_output => true,
  }

}
