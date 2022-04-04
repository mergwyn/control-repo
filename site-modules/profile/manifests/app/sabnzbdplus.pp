# @summary set up nzb downloader
#
# TODO: complete testing of settings setup
#
class profile::app::sabnzbdplus (
  String $user  = lookup('defaults::media_user'),
  String $group = lookup('defaults::media_group'),
  Optional[Hash] $settings = {},
  Boolean $use_ppa = true,
  String $ppa = 'ppa:jcfp/nobetas',
  ) {

  if $use_ppa {
    apt::ppa { $ppa: ensure => present }
  } else {
    apt::ppa { $ppa: ensure => absent }
  }

  package { 'sabnzbdplus':
    ensure  => present,
  }

# TODO this will be replaced in time by installed version from package
  $service = 'sabnzbd@.service'
  systemd::unit_file { $service:
    enable  => false,
    active  => false,
    content => @("EOT"),
      [Unit]
      Description=SABnzbd binary newsreader
      Documentation=https://sabnzbd.org/wiki/
      Wants=network-online.target
      After=network-online.target

      [Service]
      Environment="PYTHONIOENCODING=utf-8"
      #ExecStart=/opt/sabnzbd/SABnzbd.py --logging 1 --browser 0
      ExecStart=/usr/bin/sabnzbdplus --logging 1 --browser 0
      User=%I
      Type=simple
      Restart=on-failure

      [Install]
      WantedBy=multi-user.target
      | EOT
  }
# remove sysvinit files ready to replace with systemd
  file { [ '/etc/init.d/sabnzbdplus', '/etc/default/sabnzbdplus' ]:
    ensure => absent,
  }

# Keep this separate to allow wait for 
  $service_user = "sabnzbd@${user}.service"

  systemd::dropin_file { 'sabnazbd-sssd-wait.conf':
      unit    => $service,
      content => @("EOT"/),
                 [Unit]
                 After=nss-user-lookup.target
                 | EOT
      notify  => Service[$service_user],
  }
  file { "/etc/systemd/system/${service}.d/wait-ssd.conf":
    ensure => absent,
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
