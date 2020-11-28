# @summary Packages for windows

class profile::platform::baseline::windows::packages {

  include chocolatey

  Package {
    ensure   => present,
    provider => 'chocolatey',
    install_options => [ '--no-progress', ]
  }

  package { 'rsat': install_options => [ { '-params' => '/AD /GP /DNS', } ] }
  package { 'wsl-ubuntu-2004': }
  package { 'chocolateygui': }
  package { 'firefox': }
  package { 'keeweb': }
  package { 'kitty': }
  package { 'mp3gain-gui': }
  package { 'mp3tag': }
  package { 'notepadplusplus': }
  package { 'puppet-agent': }
  package { 'zabbix-agent': }

  package { 'wsl-ubuntu-1804': ensure => absent }
  package { 'dropbox':         ensure => absent }

}
