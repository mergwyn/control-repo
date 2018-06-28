#

class profile::web_server {
  include nginx
  package { [ 'fcgiwrap' ]: }
}
#
# vim: sw=2:ai:nu expandtab
