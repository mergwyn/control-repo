# @summary Install kopia
#
# @param topdir
# @param config
# @param snapbefore
# @param snapafter
# @param folderbefore
# @param folderafter
# @param maintenance
# @param args
# @param backup_files_exclude
# @param repos
#
class profile::app::kopia (
  Stdlib::Absolutepath $topdir                          = '/etc/kopia',
  Stdlib::Absolutepath $config                          = "${topdir}/config.d",
  Stdlib::Absolutepath $snapbefore                      = "${topdir}/snap-before",
  Stdlib::Absolutepath $snapafter                       = "${topdir}/snap-after",
  Stdlib::Absolutepath $folderbefore                    = "${topdir}/folder-before",
  Stdlib::Absolutepath $folderafter                     = "${topdir}/folder-after",
  Boolean $maintenance                                  = false,
  String $args                                          = '--log-level=error --no-progress',
  String $repos                                         = '',
  Optional[
    Variant[
      Variant[String,Array[String]],
      Hash[String, Variant[String,Array[String]]]
    ]
  ] $backup_files_exclude,

) {
  include profile::app::scripts

# Install kopia
  apt::keyring { 'kopia-keyring.gpg':
    source => 'puppet:///modules/profile/kopia-keyring.gpg',
  }
  apt::source { 'kopia':
    source_format => 'sources',
    location      => 'http://packages.kopia.io/apt',
    release       => 'stable',
    repos         => 'main',
    keyring       => '/etc/apt/keyrings/kopia-keyring.gpg',
  }
  package { ['kopia']: }
  file {['/etc/apt/sources.list.d', '/etc/apt/keyrings/kopia-keyring.asc']: ensure => absent }

# setup directory structure
  file {[$topdir, $config, $snapbefore, $snapafter, $folderbefore, $folderafter]:
    ensure => directory,
  }
# TODO replicate code to add pre and postdump backuppc scripts

# Daily backup script
  shellvar {
    default:
      ensure => present,
      target => '/etc/default/kopia',
      ;
    'MAINTENANCE': value => $maintenance, ;
    'ARGS':        value => $args, ;
    'REPOS':       value => $repos, ;
  }
  file { '/etc/cron.daily/kopia-backup':
    ensure => file,
    mode   => '0755',
    source => 'puppet:///modules/profile/kopia-backup',
  }
  file { '/etc/cron.weekly/kopia-maintenance':
    ensure => file,
    mode   => '0755',
    source => 'puppet:///modules/profile/kopia-maintenance',
  }

# Create backup excludes from the backuppc values
# TODO switch to kopia values
  file { '/.kopiaignore':
    ensure  => file,
    content => inline_template('<% @backup_files_exclude.keys.sort.each do |key| -%><% @backup_files_exclude[key].each do |exclude| %><%= exclude %><%= "\n" %><% end %><% end %>'),
  }
}
