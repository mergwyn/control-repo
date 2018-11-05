#

class profile::puppet::agent {

  include ::sudo
  include profile::puppet::repo
  
  # make sure we match srver version
  #
  apt::pin { 'puppet-agent':
    priority        => 501,
    release_version => '5.5*'
  }

  file { '/etc/profile.d/puppet.sh':
    ensure  => present,
    content => "# Expand the PATH to include puppet binaries\nPATH=\$PATH:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin\n"
  }
}
# vim: sw=2:ai:nu expandtab
