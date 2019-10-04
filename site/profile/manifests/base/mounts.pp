#
# Dynamically create Puppet File resources using the Puppet built-in
# 'create_resources' function.
#

class profile::base::mounts (
  Hash           $objects  = {},
  Optional[Hash] $defaults = {},
) {

  unless empty ($objects) {
    create_resources(mounts, $objects, $defaults)
  }

}

# vim: sw=2:ai:nu expandtab
