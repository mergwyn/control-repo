#
# Dynamically create Puppet File resources using the Puppet built-in
# 'create_resources' function.
#

class profile::base::users (
  Hash           $objects  = {},
  Optional[Hash] $defaults = {},
) {

  unless empty ($objects) {
    create_resources(user, $objects, $defaults)
  }

}

# vim: sw=2:ai:nu expandtab
