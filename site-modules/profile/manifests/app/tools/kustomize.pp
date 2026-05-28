#
#
class profile::app::tools::kustomize (
  String $version = '5.8.1', # renovate: datasource=github-releases depName=kubernetes-sigs/kustomize
) {
  profile::app::binary_install { 'kustomize':
    version     => $version,
    binary      => 'kustomize',
    url         => "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${version}/kustomize_v${version}_linux_amd64.tar.gz",
    tarball     => true,
    tar_extract => 'kustomize',
    version_cmd => 'kustomize version',
  }
}
