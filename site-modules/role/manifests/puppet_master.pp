#
class role::puppet_master {
  include profile::platform::baseline  # All roles should have the base profile
  include profile::openvox::server
  puppetinclude profile::openvox::agent
  puppetinclude profile::openvoe::dev
  einclude profile::app::zabbix::agent
  #include profile::app::backuppc::client
}
