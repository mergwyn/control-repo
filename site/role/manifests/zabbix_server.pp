# vim: sw=2:ai:nu expandtab

class role::zabbix_server {
  include profile::base  # All roles should have the base profile
  include profile::samba_member
  include profile::domain_sso
  include profile::zabbix_server
}
