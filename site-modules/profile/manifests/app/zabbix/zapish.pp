# @summary Install zapish for script based api access
#
class profile::app::zabbix::zapish (
  String[1]            $user     = 'root',
  Stdlib::Absolutepath $home_dir = '/root',
){

# For zabbixapi
  package { [ 'build-essential' ] : }

# Install zapish from github
  $url = 'https://github.com/kloczek/zapish'
  $dir = '/opt/zapish'

  include profile::app::git
  ensure_package {'make': }

  vcsrepo { $dir:
    ensure   => latest,
    provider => git,
    require  => Package['git'],
    source   => $url,
    revision => 'master',
    notify   => Exec['make zapish'],
  }
  exec { 'make zapish':
    path        => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
    command     => '/usr/bin/make install',
    cwd         => $dir,
    require     => Package['make'],
    refreshonly => true,
  }

# setup zabbix access token 
  $config_dir = "${home_dir}/.config"
  $config_file = "${config_dir}/zapish"

  file { $config_dir:
    ensure => directory,
  }

  $zabbix_server = lookup('defaults::zabbix_url')

  shellvar { 'zapish_url':
    ensure => present,
    target => $config_file,
    value  => "http://${zabbix_server}/api_jsonrpc.php"
  }

  shellvar { 'zapish_auth':
    ensure => present,
    target => $config_file,
    value  => lookup('secrets::zapish_token'),
  }

}
