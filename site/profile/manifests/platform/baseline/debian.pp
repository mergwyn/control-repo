#

class profile::platform::baseline::debian {

  include profile::platform::baseline::users::debian
  include profile::platform::baseline::debian::apparmor

  include profile::os::debian::base
  include profile::base::mounts
  include profile::base::ssh_server
  include profile::base::mail_client
  include profile::base::unattended_upgrades
  include profile::base::avahi
  #include profile::service::webmin
  #include profile::backuppc::client

}
