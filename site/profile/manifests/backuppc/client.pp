#
class profile::backuppc::client (
  $scripts  = '/etc/backuppc-scripts',
  $preuser  = "${scripts}/DumpPreUser",
  $postuser = "${scripts}/DumpPostUser",
  ) {


  file {[$scripts, $preuser, $postuser]:
    ensure  => directory,
  }

  file { "${preuser}/S10dirsonly":
    ensure => present,
    source => 'puppet:///modules/profile/backuppc/S10dirsonly',
    mode   => '0555',
  }

  #package { 'rsync': ensure => installed }
  include backuppc::client

  if empty(hiera('backuppc::params::system_account'))
  {
    # Need to manage .ssh keys outside of backuupc module
    $system_account        = lookup('defaults::system_user')
    $system_home_directory = lookup('defaults::system_home_dir')
    $backuppc_hostname     = lookup('defaults::backuppc_server')

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
