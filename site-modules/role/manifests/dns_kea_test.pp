#
class role::dns_kea_test {
  include profile::platform::baseline  # All roles should have the base profile
#  include profile::app::dhcpd
  include profile::app::sssd
#  include profile::app::samba::dc

  include profile::app::dns
  include profile::app::dhcp

  #include profile::app::zabbix::agent
  #include profile::app::backuppc::client
  #include profile::app::keepalived::dns
}
