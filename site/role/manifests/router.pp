# vim: sw=2:ai:nu expandtab

class role::router {
  include profile::base  # All roles should have the base profile
  include profile::router
}
