#

class profile::puppet::agent {

  include ::sudo
  
  # make sure we match srver version
  class {'::puppet_agent':
    #package_version => $serverversion,
  }

  file { '/etc/profile.d/puppet.sh':
    ensure  => present,
    content => "# Expand the PATH to include puppet binaries\nPATH=\$PATH:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin\n"
  }
}
# vim: sw=2:ai:nu expandtab
