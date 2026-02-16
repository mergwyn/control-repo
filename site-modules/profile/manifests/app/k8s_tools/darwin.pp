#
#
class profile::app::k8s_tools::darwin {
  Package {
    ensure   => latest,
    provider => 'brew',
  }

  package { [
    'kubectl',
    'helm',
    'helmfile',
    'kubectx', # includes kubens
    'sops',
    'age',
    'argocd',
    'kustomize',
    'velero',
    'cilium-cli',
  ]: }
}
