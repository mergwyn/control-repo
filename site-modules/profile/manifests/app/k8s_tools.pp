#
class profile::app::k8s_tools (
  String $argocd_version    = '3.3.0',
  String $cilium_version    = '0.19.0',
  String $helmfile_version  = '0.162.0',
  String $kustomize_version = '5.8.1',
  String $sops_version      = '3.11.0',
  String $velero_version    = '1.17.2',
) {
  case $facts['os']['family'] {
    'Debian': {
      include profile::app::k8s_tools::debian
      class { 'profile::app::helmfile':
        version => $helmfile_version,
      }
      class { 'profile::app::cilium_cli':
        version => $cilium_version,
      }
      class { 'profile::app::argocd':
        version => $argocd_version,
      }
      class { 'profile::app::sops':
        version => $sops_version,
      }
      class { 'profile::app::kustomize':
        version => $kustomize_version,
      }
      class { 'profile::app::velero':
        version => $velero_version,
      }
    }
    'Darwin': {
      include profile::app::k8s_tools::darwin
    }
    default: { fail("Unsupported OS family: ${facts['os']['family']}") }
  }
}
