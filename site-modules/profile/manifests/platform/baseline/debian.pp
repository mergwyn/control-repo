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
  include profile::platform::baseline::debian::mounts
  include profile::platform::baseline::debian::logrotate
  include profile::platform::baseline::debian::sysctl
  #include profile::platform::baseline::debian::systemd_timers
  include profile::platform::baseline::debian::usb

  # TODO: include profile::platform::baseline::debian::netplan

  include profile::app::avahi
  #include profile::service::webmin
  #include profile::app::backuppc::client

}
