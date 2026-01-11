# @summary Setup of pupper development
#
class profile::openvox::dev {
  package { 'puppet-lint':
    ensure   => 'installed',
    provider => 'gem',
    command  => '/opt/puppetlabs/puppet/bin/gem',
  }
  package { 'pdk': }
}
