#
# TODO: delete?

class profile::virtual::libvirt {
#  include '::libvirt' 
  class { '::libvirt':
    listen_tls => false,
    listen_tcp => true,
  }

  libvirt_pool { 'zvol':
    ensure    => present,
    type      => 'dir',
    autostart => true,
    target    => '/dev/zvol/srv/storage',
  }
  libvirt_pool { 'templates':
    ensure    => present,
    type      => 'dir',
    autostart => true,
    target    => '/dev/zvol/srv/templates',
  }
  libvirt_pool { 'images':
    ensure    => present,
    type      => 'dir',
    autostart => true,
    target    => '/srv/virtual/images',
  }
}
# vim: sw=2:ai:nu expandtab
