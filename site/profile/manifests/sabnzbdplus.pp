#
# TODO: complete testing of settings setup

class profile::sabnzbdplus (
  $user = 'media',
  $group = '513',
  $settings = {},
  ) {

  apt::ppa { 'ppa:jcfp/nobetas': 
    package_manage => true
  }
  apt::ppa { 'ppa:jcfp/sab-addons': 
    package_manage => true
  }
  package { [ 'python-sabyenc', 'par2-tbb' ]:
    ensure  => present,
    require => Apt::Ppa['ppa:jcfp/sab-addons'],
    notify  => Service['sabnzbdplus'],
  }

  package { 'sabnzbdplus':
    ensure  => present,
    require => Apt::Ppa['ppa:jcfp/nobetas'],
    notify  => Service['sabnzbdplus'],
  }

  service { 'sabnzbdplus':
    ensure  => 'running',
    enable  => true,
    require => [ 
      Package['sabnzbdplus'],
      Package['python-sabyenc'],
      Package['par2-tbb'],
    ]
  }

  augeas { 'sabnzbdplus.default':
    lens => "shellvars.lns",
    incl => '/etc/default/sabnzbdplus',
    context => '/files/etc/default/sabnzbdplus',
    notify => Service['sabnzbdplus'],
    changes => [ 
      "set START yes",
      "set USER $user:$group",
    ] 
  }

  validate_hash($settings)
  $defaults = { 'path' => '/home/media/.sabnzbd/sabnzbd.ini' }
  create_ini_settings($settings, $defaults)

}
# vim: sw=2:ai:nu expandtab
