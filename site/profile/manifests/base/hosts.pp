#
# Dynamically create Puppet File resources using the Puppet built-in
# 'create_resources' function.
#

class profile::base::hosts (
  Hash           $objects  = {},
  Optional[Hash] $defaults = {},
) {

  unless empty ($objects) {
    create_resources(host, $objects, $defaults)
  }

}

# vim: sw=2:ai:nu expandtab
