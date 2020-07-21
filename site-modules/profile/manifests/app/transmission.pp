# @summary transmission daemon
#

class profile::app::transmission  {

# TODO: settings
  include ::transmission

  $service = 'transmission-daemon.service'
  systemd::dropin_file { 'transmission-sssd-wait.conf':
      unit    => $service,
      content => @("EOT"/),
                 [Unit]
                 After=nss-user-lookup.target
                 | EOT
      notify  => Service[$service],
  }

}
