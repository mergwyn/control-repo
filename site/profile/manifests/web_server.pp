#

class profile::web_server {
  include nginx
  package { [ 'nginx-extras', 'fcgiwrap' ]: }
}
#
# vim: sw=2:ai:nu expandtab
