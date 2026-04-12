#
class role::generic_server {
  include profile::platform::baseline  # All roles should have the base profile

  include profile::app::sssd
}
