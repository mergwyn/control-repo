#

node default {
  lookup('classes', Array[String], 'unique').include

  if defined('$facts') and defined('$trusted') {
    if $trusted['extensions']['pp_role'] and !has_key($facts,'role') {
      $role = $trusted['extensions']['pp_role']
    }
    if $trusted['extensions']['pp_environment'] and !has_key($facts,'env') {
      $env = $trusted['extensions']['pp_environment']
    }
    if $trusted['extensions']['pp_datacenter'] and !has_key($facts,'datacenter') {
      $datacenter = $trusted['extensions']['pp_datacenter']
    }
    if $trusted['extensions']['pp_zone'] and !has_key($facts,'zone') {
      $zone = $trusted['extensions']['pp_zone']
    }
    if $trusted['extensions']['pp_application'] and !has_key($facts,'application') {
      $application = $trusted['extensions']['pp_application']
    }

    # Look up profiles
    lookup('profiles', Array[String], 'unique').contain

    case $::kernel {
      'Linux': {
        lookup('linux_profiles', Array[String], 'unique').contain
      }
      'Windows': {
        lookup('windows_profiles', Array[String], 'unique').contain
      }
      'Darwin': {
        lookup('darwin_profiles', Array[String], 'unique').contain
      }
      default: {
      }
    }

    ### RESOURCE DEFAULTS
    # Some resource defaults for Files and Execs
    case $::kernel {
      'Darwin': {
  File {
    owner => 'root',
    group => 'wheel',
    mode  => '0644',
  }
  Exec {
    path => $::path,
  }
      }
      'Windows': {
  File {
    owner => 'Administrator',
    group => 'Administrators',
    mode  => '0644',
  }
  Exec {
    path => $::path,
  }
      }
      default: {
  File {
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
          backup => false,              # Disable filebucket by default for all File resources:
  }
  Exec {
    path => '/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/sbin',
  }
      }
    }
  }

}
# vim: sw=2:ai:nu expandtab
