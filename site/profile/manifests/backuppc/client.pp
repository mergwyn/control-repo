#
class profile::backuppc::client (
  $scripts  = '/etc/backuppc/scripts',
  $preuser  = "${scripts}/DumpPreUser",
  $postuser = "${scripts}/DumpPostUser",
  ) {

  include backuppc::client
  file {[$scripts, $preuser, $postuser]:
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

  #package { 'rsync': ensure => installed }

  if empty hiera('backuppc::client::system_account')
  {
    # Need to manage .ssh keys outside of backuupc module
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
  }
}


# vim: sw=2:ai:nu expandtab
