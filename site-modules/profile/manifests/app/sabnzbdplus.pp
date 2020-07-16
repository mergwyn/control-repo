#
# TODO: complete testing of settings setup
# TODO install from snap store

class profile::app::sabnzbdplus (
  String $user  = lookup('defaults::media_user'),
  String $group = lookup('defaults::media_group'),
  Optional[Hash] $settings = {},
  ) {

# Tidy up old ppa based installation
  apt::ppa { [ 'ppa:jcfp/nobetas', 'ppa:jcfp/sab-addons' ]:
    ensure => absent,
  }
  package { 'sabnzbdplus': ensure  => absent, }

# Allow to run as a different user
  $service = snap.sabnzbd.sabnzbd.service
  systemd::dropin_file { 'media-user.conf':
      unit    => $service,
      content => @("EOT"/),
                 [Unit]
                 After=nss-user-lookup.target

                 [Service]
                 User=${media}
                 Group=${group}
                 | EOT
      notify  => Service[$service],
  }

# Install from snap
  package { 'sabnzbd':
    ensure   => present,
    provider => snap,
  }

# Process settings
  $defaults = { 'path' => '/home/media/.sabnzbd/sabnzbd.ini' }
  create_ini_settings($settings, $defaults)

}
