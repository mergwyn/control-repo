#
# Dynamically create Puppet Package resources using the Puppet built-in
# 'create_resources' function.
#
#
class profile::platform::baseline::packages (
  Hash           $objects  = {},
  Optional[Hash] $defaults = {},
) {

  case $::kernel {
    'Darwin': {
      include profile::platform::baseline::darwin::brew
    }
    default: {
    }
  }
  unless empty ($objects) {
    create_resources(package, $objects, $defaults)
  }

}
