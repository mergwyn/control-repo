# vim: sw=2:ai:nu expandtab

class role::print_server {
  include profile::base  # All roles should have the base profile
  include profile::print_server
}
