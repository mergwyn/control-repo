#

class profile::router {

  include ::snapd
  $snappackages = [ 'ffr' ]
  package { $snappackages:
    ensure   => present,
    provider => snap,
  }

}
#
# vim: sw=2:ai:nu expandtab
