# vim: sw=2:ai:nu expandtab

class role::dhcp_server {
  include profile::base  # All roles should have the base profile
  include profile::domain::dhcpd
}
