#
class profile::app::k8s_tools (
  String $helmfile_version = '0.162.0',
  String $cilium_version   = '1.16.1',
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
    }
    'Darwin': {
      include profile::app::k8s_tools::darwin
    }
    default: { fail("Unsupported OS family: ${facts['os']['family']}") }
  }
}
