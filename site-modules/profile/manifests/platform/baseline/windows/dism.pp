#
# Dynamically create Puppet File resources using the Puppet built-in
# 'create_resources' function.
#

class profile::platform::baseline::windows::dism (
  Hash           $objects  = {},
  Optional[Hash] $defaults = {},
) {

  dism {'Microsoft-Windows-Subsystem-Linux':
    ensure    => present,
    norestart => true,
  }

  $objects.each |String $key, Hash $value| {
    $ensure = pick($value['ensure'], 'present')
    dism { $key:
      ensure => $ensure,
      *      => $value,
    }
  }
}

