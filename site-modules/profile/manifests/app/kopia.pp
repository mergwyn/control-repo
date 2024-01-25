#
#
class profile::app::kopia (
  Stdlib::Absolutepath $topdir                          = '/etc/kopia',
  Stdlib::Absolutepath $config                          = "${topdir}/config.d",
  Stdlib::Absolutepath $snapbefore                      = "${topdir}/snap_before",
  Stdlib::Absolutepath $snapafter                       = "${topdir}/snap_after",
  Stdlib::Absolutepath $folderbefore                    = "${topdir}/folder_before",
  Stdlib::Absolutepath $folderafter                     = "${topdir}/folder_after",
  Optional[Backuppc::BackupFiles] $backup_files_exclude = $profile::app::backuppc::client::backup_files_exclude,
) {

# Install kopia
  apt::source { 'kopia':
    location => 'http://packages.kopia.io/apt',
    release  => 'stable',
    repos    => 'main',
    key      => {
      name   => 'kopia-keyring.gpg',
      source => 'https://kopia.io/signing-key',
    },
  }
  package { [ 'kopia' ] : }

# setup directory structure
  file {[$topdir, $config, $snapbefore, $snapafter, $folderbefore, $folderafter]:
    ensure  => directory,
  }
# TODO replicate code to add pre and postdump backuppc scripts

# Create backup excludes from the backuppc values
# TODO switch to kopia values
  file { '/tmp/kopiaignore.test':
    ensure  => present,
    content => inline_template('<% @backup_files_exclude.keys.sort.each do |key| -%><% @backup_files_exclude[key].each do |exclude| %><%= exclude %><%= "\n" %><% end %><% end %>')
  }

}
