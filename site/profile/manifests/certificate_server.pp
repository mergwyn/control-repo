#
class profile::certificate_server (
  Array[Stdlib::Fqdn] $domains = []
) {

  class { 'letsencrypt':
    email                =>  "ca@${facts['domain']}",
  }

  letsencrypt::certonly { $trusted['certname']:
    plugin               => 'nginx',
    domains              => $domains,
    manage_cron          => true,
    cron_success_command => 'systemctl reload nginx',
    suppress_cron_output => true,
  }
}
