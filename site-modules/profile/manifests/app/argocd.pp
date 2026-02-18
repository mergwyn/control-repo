#
#
class profile::app::argocd (
  String $version = '3.3.0',
) {
  profile::app::binary_install { 'argocd':
    version     => $version,
    binary      => 'argocd',
    url         => "https://github.com/argoproj/argo-cd/releases/download/v${version}/argocd-linux-amd64",
    # argocd will fail if the $HOME is not set
    version_cmd => 'HOME=/ argocd version --client --short',
  }
}
