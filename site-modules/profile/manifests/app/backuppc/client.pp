#
class profile::app::backuppc::client (
  Stdlib::Absolutepath $scripts                         = '/etc/backuppc-scripts',
  Stdlib::Absolutepath $preuser                         = "${scripts}/DumpPreUser",
  Stdlib::Absolutepath $postuser                        = "${scripts}/DumpPostUser",
  Backuppc::ShareName $rsync_share_name                 = '/',
  Optional[Backuppc::BackupFiles] $backup_files_exclude = undef,
  Stdlib::Fqdn $backuppc_hostname,
  ) {

  file {[$scripts, $preuser, $postuser]:
    ensure  => directory,
  }

  file { "${preuser}/S10dirsonly":
    ensure => present,
    source => 'puppet:///modules/profile/backuppc/S10dirsonly',
    mode   => '0555',
  }

  $dump_cmd = "\$sshPath -q -x -l root \$host /bin/run-parts --report ${scripts}"

  #package { 'rsync': ensure => installed }
  class { 'backuppc::client':
    config_name                => $facts['networking']['hostname'],
    client_name_alias          => "${facts['networking']['hostname']}.${facts['networking']['domain']}",
    backuppc_hostname          => $backuppc_hostname,
    rsync_share_name           => $rsync_share_name,
    backup_files_exclude       => $backup_files_exclude,
    system_account             => '',
    manage_sshkey              => false,
    hosts_file_user            => 'gary',
    hosts_file_more_users      => 'backuppc',
    email_admin_user_name      => 'backuppc',
    email_user_dest_domain     => "@${facts['networking']['domain']}",
    system_additional_commands => [
      '/bin/run-parts',
      '/etc/backuppc/scripts/DumpPreUser/*',
    ],
    dump_pre_user_cmd          => "${dump_cmd}/DumpPreUser --arg=\$type",
    dump_post_user_cmd         => "${dump_cmd}/DumpPostUser --arg=\$type --arg=\$xferOK",
    user_cmd_check_status      => true,
  }

  if lookup('backuppc::client::system_account') {
    # Need to manage .ssh keys outside of backuupc module
    $system_account        = lookup('defaults::system_user')
    $system_home_directory = lookup('defaults::system_home_dir')

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
