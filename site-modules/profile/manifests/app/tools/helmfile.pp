#
#
class profile::app::tools::helmfile (
  String $version = '1.7.1', # renovate: datasource=github-releases depName=helmfile/helmfile
) {
  profile::app::binary_install { 'helmfile':
    version     => $version,
    binary      => 'helmfile',
    url         => "https://github.com/helmfile/helmfile/releases/download/v${version}/helmfile_${version}_linux_amd64.tar.gz",
    tarball     => true,
    tar_extract => 'helmfile',
    version_cmd => 'helmfile version -o short',
  }
}
