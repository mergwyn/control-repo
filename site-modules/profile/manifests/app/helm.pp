#
#
class profile::app::helm (
  String $version = '3.20.0', # renovate: datasource=github-releases depName=helm/helm
) {
  profile::app::binary_install { 'helm':
    version     => $version,
    binary      => 'helm',
    url         => "https://get.helm.sh/helm-v${version}-linux-amd64.tar.gz",
    tarball     => true,
    tar_extract => 'linux-amd64/helm',
    version_cmd => 'helm version --short',
  }
}
