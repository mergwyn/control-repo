# @summary velero backup (k8s)
#
class profile::app::velero (
) {
  $scripts = '/etc/openvpn/scripts'

  $aptpackages = [
    'rclone',
  ]
  package { $aptpackages: ensure => present, }

#TODO rclone config
#TODO install velero

  case $facts['os']['architecture'] {
    'amd64': { $edition = 'linux-amd64' }
    default: { fail("Architecture ${facts['os']['architecture']} is not supported") }
  }

  $archive_name = "/velero.latest.${edition}.tar.gz"
  $archive_path = "${facts['puppet_vardir']}/${archive_name}"
  $install_path = '/usr/local/bin'
  $creates      = "${install_path}/velero"

  githubreleases_download { $archive_path:
    author            => 'vmware-tanzu',
    repository        => 'velero',
    asset             => true,
    asset_filepattern => $edition,
  }
  -> archive { $archive_name:
    source       => "file://${archive_path}",
    extract      => true,
    extract_path => $install_path,
    cleanup      => false,
    require      => Githubreleases_download[$archive_path],
  }


}
