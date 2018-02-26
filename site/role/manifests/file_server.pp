#

class role::file_server {
  include profile::base  # All roles should have the base profile
  include profile::samba_member
  include profile::domain_sso
  include profile::zfs_server
}
# vim: sw=2:ai:nu expandtab
