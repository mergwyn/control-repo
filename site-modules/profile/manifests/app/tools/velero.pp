# @summary velero backup (k8s)
#
class profile::app::tools::velero (
  String $version  = '1.18.2', # renovate: datasource=github-releases depName=vmware-tanzu/velero
) {
  profile::app::binary_install { 'velero':
    version         => $version,
    binary          => 'velero',
    url             => "https://github.com/vmware-tanzu/velero/releases/download/v${version}/velero-v${version}-linux-amd64.tar.gz",
    archive         => 'tar.gz',
    archive_extract => "velero-v${version}-linux-amd64/velero",
    version_cmd     => 'velero version --client-only',
  }
}
