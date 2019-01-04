#
# Dynamically create Puppet File resources using the Puppet built-in
# 'create_resources' function.
#

class profile::base::packages (
  Hash           $objects  = {},
  Optional[Hash] $defaults = {},
) {

  case $::kernel {
    'Darwin': {
      requite homebrew
    }
    default: {
    }
  }
  unless empty ($objects) {
    validate_raw_constructor ($objects)
    validate_hash ($defaults)
    create_resources(package, $objects, $defaults)
  }

}

# vim: sw=2:ai:nu expandtab
