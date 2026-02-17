#
class profile::app::k8s_tools (
  String $age_version       = '1.1.1',
  String $argocd_version    = '3.3.0',
  String $cilium_version    = '0.19.0',
  String $helm_version      = '3.20.0',
  String $helmfile_version  = '0.162.0',
  String $kubectl_version   = '0.35.1',
  String $kubectx_version   = '0.9.5',
  String $kustomize_version = '5.8.1',
  String $sops_version      = '3.11.0',
  String $velero_version    = '1.17.2',
) {
  case $facts['os']['family'] {
    'Debian': {
      class { 'profile::app::age':        version => $age_version, }
      class { 'profile::app::argocd':     version => $argocd_version, }
      class { 'profile::app::cilium_cli': version => $cilium_version, }
      class { 'profile::app::helm':       version => $helm_version, }
      class { 'profile::app::helmfile':   version => $helmfile_version, }
      class { 'profile::app::kubectl':    version => $kubectl_version, }
      class { 'profile::app::kubectx':    version => $kubectx_version, }
      class { 'profile::app::kustomize':  version => $kustomize_version, }
      class { 'profile::app::sops':       version => $sops_version, }
      class { 'profile::app::velero':     version => $velero_version, }
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
