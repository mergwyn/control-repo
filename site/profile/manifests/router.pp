#

class profile::router {

  $aptpackages = [
    'ufw',
    'openvpn-client',
  ]
  package { $aptpackages: ensure   => present, }

}
#
# vim: sw=2:ai:nu expandtab
