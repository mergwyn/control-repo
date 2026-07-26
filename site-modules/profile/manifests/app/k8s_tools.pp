#
class profile::app::k8s_tools {
  case $facts['os']['family'] {
    'Debian': {
      include profile::app::tools::age
      include profile::app::tools::argocd
      include profile::app::tools::cilium_cli
      include profile::app::tools::helm
      include profile::app::tools::helmfile
      include profile::app::tools::kube_ps1
      include profile::app::tools::kubectl
      include profile::app::tools::kubectx  # includes kubens
      include profile::app::tools::kustomize
      include profile::app::tools::sops
      include profile::app::tools::velero
    }
    'Darwin': {
      Package {
        ensure   => latest,
        provider => 'homebrew',
      }

      package { [
        'age',
        'argocd',
        'cilium-cli',
        'helm',
        'helmfile',
        'kube-ps1',
        'kubectl',
        'kubectx', # includes kubens
        'kustomize',
        'sops',
        'velero',
      ]: }
    }
    default: { fail("Unsupported OS family: ${facts['os']['family']}") }
  }
}
