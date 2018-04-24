#
class profile::backuppc_client {
  $scripts='/etc/backuppc/scripts/'
  $dir="${scripts}DumpPreUser/'
  file {['/etc/backuppc','/etc/backuppc/scripts',"${dir}"]:
    ensure => directory
  }

  file { "${dir}/S10dirsonly":
    ensure => present,
    source => 'puppet:///modules/profile/backuppc/S10dirsonly',
    mode   => '0555',
  }
  file { "${dir}/S20mysql-backup":
    ensure => present,
    source => 'puppet:///modules/profile/backuppc/S20mysql-backup',
    mode   => '0555',
  }
  file { "${scripts}/S20mysql-backup-password":
    ensure => present,
    content => sprintf("PASSWORD=%s\n",hiera("passwords::mysql")),
    mode   => '0555',
  }
  file { "${dir}/S20mysql-backup-password":
    ensure => absent,
  }
  package { 'rsync': ensure => installed }
}
# vim: sw=2:ai:nu expandtab
