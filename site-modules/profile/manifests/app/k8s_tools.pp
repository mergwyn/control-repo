#
class profile::app::k8s_tools {
  case $facts['os']['family'] {
    'Debian': {
      include profile::app::age
      include profile::app::argocd
      include profile::app::cilium_cli
      include profile::app::helm
      include profile::app::helmfile
      include profile::app::kube_ps1
      include profile::app::kubectl
      include profile::app::kubectx
      include profile::app::kustomize
      include profile::app::sops
      include profile::app::velero
    }
    'Darwin': {
      Package {
        ensure   => latest,
        provider => 'brew',
      }

      package { [
        'age',
        'argocd',
        'cilium-cli',
        'helm',
        'helmfile',
        'kube_ps1',
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
