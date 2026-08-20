#
#
class profile::app::tools::cilium_cli (
  String $version = '0.19.7', # renovate: datasource=github-releases depName=cilium/cilium-cli
) {
  profile::app::binary_install { 'cilium':
    version         => $version,
    binary          => 'cilium',
    url             => "https://github.com/cilium/cilium-cli/releases/download/v${version}/cilium-linux-amd64.tar.gz",
    archive         => 'tar.gz',
    archive_extract => 'cilium',
    version_cmd     => "cilium version --client | grep 'cilium-cli'",
  }
}
