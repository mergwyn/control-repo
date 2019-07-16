#
# Dynamically create Puppet File resources using the Puppet built-in
# 'create_resources' function.
#

class profile::base::tasks (
  Hash           $objects  = {},
  Optional[Hash] $defaults = {},
) {

  case $::kernel {
    'windows': {
      unless empty ($objects) {
        create_resources(scheduled_task, $objects, $defaults)
      }
    }
    default: {
    }
  }

}

# vim: sw=2:ai:nu expandtab
