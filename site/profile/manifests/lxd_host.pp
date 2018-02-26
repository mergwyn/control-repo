#

class profile::lxd_host {
  package { 'lxd': }
  service { 'lxd':
    ensure  => 'running',
    #enable  => true,
    require => Package['lxd'],
  }
}
# vim: sw=2:ai:nu expandtab
