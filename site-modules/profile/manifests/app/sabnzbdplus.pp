# @summary set up nzb downloader
#
# TODO: complete testing of settings setup

class profile::app::sabnzbdplus (
  String $user  = lookup('defaults::media_user'),
  String $group = lookup('defaults::media_group'),
  Optional[Hash] $settings = {},
  ) {

# Tidy up old ppa based installation
  apt::ppa { [ 'ppa:jcfp/nobetas', 'ppa:jcfp/sab-addons' ]:
    ensure => absent,
  }

  package { 'sabnzbdplus':
    ensure  => present,
  }

# Run as a different user
  $service = 'sabnzbdplus@.service'
  $service_user = "sabnzbdplus@${user}.service"

  systemd::dropin_file { 'wait-ssd.conf':
      unit    => $service,
      content => @("EOT"/),
                 [Unit]
                 After=nss-user-lookup.target
                 | EOT
      notify  => Service[$service_user],
  }

  service { $service_user:
    ensure  => running,
    enable  => true,
    require => Package['sabnzbdplus'],
  }

# Process settings
  $defaults = { 'path' => '/home/media/.sabnzbd/sabnzbd.ini' }
  create_ini_settings($settings, $defaults)

}
