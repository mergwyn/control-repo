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
      require homebrew
    }
    default: {
    }
  }
  unless empty ($objects) {
    create_resources(package, $objects, $defaults)
  }

}

# vim: sw=2:ai:nu expandtab
