#
# Dynamically create Puppet File resources using the Puppet built-in
# 'create_resources' function.
#

class profile::base::dism (
  Hash           $objects  = {},
  Optional[Hash] $defaults = {},
) {

  $objects.each |String $key, Hash $value| {
    $ensure = pick($value['ensure'], 'present')
    dism { $key:
      ensure => $ensure,
      *      => $value,
    }
  }
}

# vim: sw=2:ai:nu expandtab
