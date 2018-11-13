#

class profile::router {

  $packages = [ 'pfsense' ]
  package { $packages: ensure => present }

}
#
# vim: sw=2:ai:nu expandtab
