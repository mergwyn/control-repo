# @summary Setup of pupper development

class profile::puppet::dev {

  package { 'puppet-lint':
    ensure   => 'installed',
    provider => 'gem',
    command  => '/opt/puppetlabs/puppet/bin/gem',
  }
  package { 'pdk': }

}
