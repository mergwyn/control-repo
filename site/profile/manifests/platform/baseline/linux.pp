#

class profile::platform::baseline::linux {

  include profile::os::debian::base
  include profile::base::mounts
  include profile::base::ssh_server
  include profile::base::mail_client
  include profile::base::unattended_upgrades
  include profile::base::avahi
  #include profile::service::webmin
  #include profile::backuppc::client

}