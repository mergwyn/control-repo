#

class role::backup_server {
  include profile::base  # All roles should have the base profile
  include profile::domain::member
  include profile::domain::sso
  include profile::backuppc::server
}
# vim: sw=2:ai:nu expandtab
