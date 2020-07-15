#

class profile::platform::baseline::debian {

  include profile::platform::baseline::users::debian
  include profile::platform::baseline::debian::apparmor
  include profile::platform::baseline::debian::packages
  include profile::platform::baseline::debian::hosts
  include profile::platform::baseline::debian::unattended_upgrades
  include profile::platform::baseline::debian::ntp
  include profile::platform::baseline::debian::timezone
  include profile::platform::baseline::debian::postfix
  include profile::platform::baseline::debian::ssh
  # TODO: include profile::platform::baseline::debian::netplan

  include profile::base::mounts
  include profile::base::avahi
  #include profile::service::webmin
  #include profile::app::backuppc::client

}
