#
class profile::app::k8s_tools (
  String $helmfile_version = '1.2.3',
  String $cilium_version   = '1.19.0',
  String $argocd_version   = '3.3.0',
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
    }
    'Darwin': {
      include profile::app::k8s_tools::darwin
    }
    default: { fail("Unsupported OS family: ${facts['os']['family']}") }
  }
}
