#
# TODO: 

class profile::jackett () {

  #TODO insert dependency on mono into module
  include profile::mono
  include ::jackett
}
# vim: sw=2:ai:nu expandtab
