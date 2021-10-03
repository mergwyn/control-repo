# @summary radarr movie downloader
#
#
class profile::app::radarr  {

# TODO: settings
  include ::radarr

  $service = 'radarr.service'
  systemd::dropin_file { 'radarr-sssd-wait.conf':
      unit    => $service,
      content => @("EOT"/),
                 [Unit]
                 After=nss-user-lookup.target
                 | EOT
      notify  => Service[$service],
  }

}
