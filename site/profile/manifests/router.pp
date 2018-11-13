#

class profile::router {

  include ::snapd
  $snappackages = [ 'frr' ]
  package { $snappackages:
    ensure   => present,
    provider => snap,
  }

}
#
# vim: sw=2:ai:nu expandtab
