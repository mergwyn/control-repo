# @summary Packages for windows
#
class profile::platform::baseline::windows::packages {

  include chocolatey

  Package {
    ensure   => present,
    provider => 'chocolatey',
    install_options => [ '--no-progress', ]
  }

  package { 'rsat': install_options => [ { '-params' => '/AD /GP /DNS', } ] }
  package { 'chocolateygui': }
  package { 'notepadplusplus': }
  package { 'puppet-agent': }
  package { 'zabbix-agent': }
}
