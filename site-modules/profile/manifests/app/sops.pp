#
#
class profile::app::sops (
  String $version = '3.12.1', # renovate: datasource=github-releases depName=getsops/sops
) {
  profile::app::binary_install { 'sops':
    version     => $version,
    binary      => 'sops',
    url         => "https://github.com/getsops/sops/releases/download/v${version}/sops-v${version}.linux.amd64",
    version_cmd => 'sops --version',
  }
}
