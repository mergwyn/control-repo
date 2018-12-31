#
# Dynamically create Puppet File resources using the Puppet built-in
# 'create_resources' function.
#

class profile::base::homebrew (
  $objects  = {},
  $defaults = {},
) {

  unless empty ($objects) {
    validate_raw_constructor ($objects)
    validate_hash ($defaults)
    create_resources(homebrew, $objects, $defaults)
  }

}

# vim: sw=2:ai:nu expandtab
