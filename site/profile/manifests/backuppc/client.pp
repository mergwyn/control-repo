#
class profile::backuppc::client (
  $scripts  = '/etc/backuppc/scripts',
  $preuser  = "${scripts}/DumpPreUser",
  $postuser = "${scripts}/DumpPostUser",
  ) {

  file {['/etc/backuppc',$scripts, $preuser, $postuser]:
    ensure  => directory,
    recurse => true,
  }
  file {[ "${scripts}/PreUser", "${scripts}/PostUser"]:
    ensure => absent,
    force  => true,
  }

  file { "${preuser}/S10dirsonly":
    ensure => present,
    source => 'puppet:///modules/profile/backuppc/S10dirsonly',
    mode   => '0555',
  }
  file { "${preuser}/S20mysql-backup": ensure  => absent, }
  file { "${scripts{/S20mysql-backup-password": ensure  => absent, }

  package { 'rsync': ensure => installed }

  # backuppc ssh keys
  $system_account        = hiera('defaults::system_user')
  $system_home_directory = hiera('defaults::system_home_dir')
  $backuppc_hostname     = hiera('defaults::backuppc_server')

  file { "${system_home_directory}/.ssh":
    ensure => 'directory',
    mode   => '0700',
    owner  => $system_account,
    group  => $system_account,
  }
  Ssh_authorized_key <<| tag == "backuppc_${backuppc_hostname}" |>> {
    ensure  => present,
    user    => $system_account,
    require => File["${system_home_directory}/.ssh"]
  }

#  if $facts['networking']['fqdn'] != $backuppc_hostname {
#    @@sshkey { $facts['networking']['fqdn']:
#      ensure => $ensure,
#      type   => 'ssh-rsa',
#      key    => $facts['ssh']['rsa']['key'],
#      tag    => "backuppc_sshkeys_${backuppc_hostname}",
#    }
#  }
}


# vim: sw=2:ai:nu expandtab
