# @summary manage letsencrypt certificates

class profile::app::gateway::certs {
# TODO find a way of providing a common list of certs

  if $facts['os']['family'] != 'Debian' {
    fail("${title} is only for Debian")
  }

  package { 'python3-certbot-nginx': }

# This options file allows for a working nginx config even if the certs do not exist
# The hook below on certificate creation works together with the include_files in the host
  $nginx_conf = '/etc/nginx/options-ssl-nginx.conf'
  file { $nginx_conf:
    require => Package[nginx],
    content => @("EOT"/),
               ssl_certificate           /etc/letsencrypt/live/${trusted['certname']}/fullchain.pem;
               ssl_certificate_key       /etc/letsencrypt/live/${trusted['certname']}/privkey.pem;
               | EOT
  }

# deploy hook to link the optiosn file once the certifcates are created
# TODO check for existance of perm and cert file
  file { '/etc/letsencrypt/renewal-hooks/deploy/nginx-conf':
    require => File[$nginx_conf],
    mode    => '0555',
    content => @("EOT"/),
               #!/usr/bin/env bash
               echo "Deploy hook for \$CERTBOT_ALL_DOMAINS"
               if [[ -f ${nginx_conf} ]] 
               then
                 ln -s ${nginx_conf} /etc/nginx/snippets
                 systemctl restart nginx
               fi
               | EOT
  }

# TODO is this necessary - check systemd timer
  class { 'letsencrypt':
    email             => "ca@${facts['domain']}",
    renew_cron_ensure => 'absent',
    #renew_cron_ensure   => 'present',
    #renew_cron_minute   => 0,
    #renew_cron_hour     => 6,
    #renew_cron_monthday => '1-31/2',
  }

  letsencrypt::certonly { $trusted['certname']:
    plugin               => 'nginx',
    domains              => [
                              $trusted['domain'],
                              $trusted['certname'],
                              "foxtrot.${$trusted['domain']}",
                              "tango.${$trusted['domain']}",
                              "zulu.${$trusted['domain']}",
#  "echo.%{trusted.domain}"
                            ],
    manage_cron          => false,
    cron_success_command => 'systemctl reload nginx',
    suppress_cron_output => true,
  }

}
