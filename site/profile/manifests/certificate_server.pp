#

class profile::certificate_server {

  include letsencrypt

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
