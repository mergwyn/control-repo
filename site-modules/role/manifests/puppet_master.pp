#
class role::puppet_master {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::openvox::server
  include profile::openvox::agent
  include profile::openvox::dev
  include profile::app::kopia
  include profile::app::sssd
}
