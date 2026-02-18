#
#
class profile::app::cilium_cli (
  String $version = '0.19.0',
) {
  profile::app::binary_install { 'cilium':
    version     => $version,
    binary      => 'cilium',
    url         => "https://github.com/cilium/cilium-cli/releases/download/v${version}/cilium-linux-amd64.tar.gz",
    tarball     => true,
    tar_extract => 'cilium',
    version_cmd => "cilium version --client | grep 'cilium-cli'",
  }
}
