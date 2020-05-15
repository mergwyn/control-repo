#

class profile::certificate_server {

  # sort out certificates first
  include letsencypt
  #class { '::letsencrypt':
  #  config => {
  #    email  => lookup('defaults::adminemail'),
  #    server => 'https://acme-staging.api.letsencrypt.org/directory'
  #  }
  #}

  $domain = $::facts['networking']['domain']
  letsencrypt::certonly { 'home':
    plugin               => 'nginx',
    domains              => [
      $facts['networking']['fqdn'],
      "echo.${domain}",
      "foxtrot.${domain}",
      "tango.${domain}",
      "vpn.${domain}"
    ],
    manage_cron          => true,
    cron_before_command  => 'service nginx stop',
    cron_success_command => '/bin/systemctl reload nginx.service',
    suppress_cron_output => true,
  }

}
