# vim: sw=2:ai:nu expandtab

class role::puppet_master {
  include profile::base  # All roles should have the base profile
  include profile::puppet_master 
  include profile::puppet_agent
  include profile::domain::member
  include profile::domain::sso
}
