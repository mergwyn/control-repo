# @summary Setup of puppet development tools
#
class profile::openvox::dev {
  package { 'puppet-lint':
    ensure   => 'installed',
    provider => 'gem',
    command  => '/opt/puppetlabs/puppet/bin/gem',
  }
}
