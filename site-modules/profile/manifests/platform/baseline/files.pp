#
# Dynamically create Puppet File resources using the Puppet built-in
# 'create_resources' function.
#

class profile::platform::baseline::files (
  Hash           $objects  = {},
  Optional[Hash] $defaults = {},
) {

  unless empty ($objects) {
    create_resources(file, $objects, $defaults)
  }

}
