# vim: sw=2:ai:nu expandtab

class role::domain_controller {
  include network
  include profile::base  # All roles should have the base profile
  include profile::domain::dhcpd
  include profile::domain::dc # this always only a secondary controller
  include profile::domain::sso
}
