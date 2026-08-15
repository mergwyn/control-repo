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
# @param repos
# @param snaps
# @param backup_files_exclude
# @param common_excludes
#
class profile::app::kopia (
  Stdlib::Absolutepath $topdir       = '/etc/kopia',
  Stdlib::Absolutepath $config       = "${topdir}/config.d",
  Stdlib::Absolutepath $snapbefore   = "${topdir}/snap-before",
  Stdlib::Absolutepath $snapafter    = "${topdir}/snap-after",
  Stdlib::Absolutepath $folderbefore = "${topdir}/folder-before",
  Stdlib::Absolutepath $folderafter  = "${topdir}/folder-after",
  Boolean $maintenance               = false,
  String $args                       = '--log-level=error --no-progress',
  Array[String] $repos               = [],
  Array[Stdlib::Absolutepath] $snaps = ['/'],
  Optional[
    Hash[
      Stdlib::Absolutepath,
      Variant[String, Array[String]]
    ]
  ] $backup_files_exclude            = undef,
  Array[String] $common_excludes     = [],
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
  file { ['/etc/apt/sources.list.d/kopia.list', '/etc/apt/keyrings/kopia-keyring.asc']: ensure => absent }
  # setup directory structure
  file { [$topdir, $config, $snapbefore, $snapafter, $folderbefore, $folderafter]:
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
    'REPOS':       value => join($repos, ' '), ;
    'SNAPS':       value => join($snaps, ',') ;
  }
  file { '/etc/cron.daily/kopia-backup':
    ensure => file,
    mode   => '0755',
    source => 'puppet:///modules/profile/kopia-backup',
  }
  file { '/etc/cron.daily/kopia-maintenance':
    ensure => file,
    mode   => '0755',
    source => 'puppet:///modules/profile/kopia-maintenance',
  }
  file { '/etc/cron.weekly/kopia-maintenance':
    ensure => absent,
  }
  $bws_token = lookup('secrets::kopia::bws_token')
  file { "${topdir}/.bws_env":
    ensure  => file,
    owner   => 'root',
    group   => 'Domain Admins',
    mode    => '0640',
    content => "export BWS_ACCESS_TOKEN=${bws_token}\n",
  }

  # Create path-aware .kopiaignore files, one per snapshot root, merging
  # common excludes with any path-specific excludes for that root.
  $exclude_paths = $backup_files_exclude ? {
    undef   => {},
    default => $backup_files_exclude,
  }

  # Union of declared snapshot roots and any exclude-hash keys, so a path
  # with no specific excludes still gets the common set rather than nothing.
  $all_snap_paths = ($snaps + $exclude_paths.keys).unique

  $all_snap_paths.each |$path| {
    $path_rules = $exclude_paths[$path] ? {
      undef   => [],
      String  => [$exclude_paths[$path]],
      default => $exclude_paths[$path],
    }
    $content = ($common_excludes + $path_rules).unique

    if !empty($content) {
      file { "${path}/.kopiaignore":
        ensure  => file,
        content => "${join($content, "\n")}\n",
      }
    }
  }
}
