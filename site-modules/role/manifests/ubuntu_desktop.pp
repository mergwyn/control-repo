#
class role::ubuntu_desktop {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::app::sssd

  #include profile::app::backuppc::client
  include profile::app::kopia
  include profile::app::unison
  include profile::app::git
  include profile::app::scripts
}
