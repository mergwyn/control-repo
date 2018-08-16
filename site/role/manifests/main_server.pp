#

class role::main_server {
  include profile::base  # All roles should have the base profile
  include profile::samba_member
  include profile::domain_sso
  include profile::nfs_server
  include profile::web::webdav
  include profile::web::munki
  include profile::photos
  include profile::mac::timemachine_server
  include profile::mailman_rss
}
# vim: sw=2:ai:nu expandtab
