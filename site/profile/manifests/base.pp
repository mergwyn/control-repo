#

class profile::base {
  include profile::base::users
  include profile::base::files
  include profile::base::packages
}
# vim: sw=2:ai:nu expandtab
