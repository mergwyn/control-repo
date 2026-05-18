# @summary Install argocd at a specified version
#
class profile::app::argocd (
  String $version = '3.4.2', # renovate: datasource=github-releases depName=argoproj/argo-cd
) {
  profile::app::binary_install { 'argocd':
    version     => $version,
    binary      => 'argocd',
    url         => "https://github.com/argoproj/argo-cd/releases/download/v${version}/argocd-linux-amd64",
    version_cmd => 'argocd version --client --short',
    env_vars    => ['HOME=/'],
  }
}
