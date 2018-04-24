# vim: sw=2:ai:nu expandtab

class role::internet_gateway {
  include profile::base  # All roles should have the base profile
  include profile::reverse_proxy
  include profile::ddclient
}
