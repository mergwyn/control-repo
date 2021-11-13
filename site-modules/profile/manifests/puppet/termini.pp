# @summary Install and configure puppetdb-termini
#
# @param server
#   FQDN of the puppet server
# @param port
#   Port number of the server
# @param soft_write_failure
#   Enable to handle failing silently when your PuppetDB is not available
# @param puppet_confdir
#   Directory for puppet config files
#
class profile::puppet::termini (
  Stdlib::Fqdn $server                 = lookup('puppet::puppet_server'),
  Stdlib::Port $port                   = 8081,
  Boolean $soft_write_failure          = false,
  Stdlib::Absolutepath $puppet_confdir = '/etc/puppetlabs/puppet',
) {

  include profile::puppet::repo

  package { 'puppetdb-termini': ensure => installed, }

  Ini_setting {
    ensure  => present,
    section => 'main',
    path    => "${puppet_confdir}/puppetdb.conf",
  }

  ini_setting { 'puppetdbserver_urls':
    setting => 'server_urls',
    value   => "https://${server}:${port}/",
  }

  ini_setting { 'soft_write_failure':
    setting => 'soft_write_failure',
    value   => $soft_write_failure,
  }

}
