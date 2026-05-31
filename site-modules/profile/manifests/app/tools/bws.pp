# @summary Installs the Bitwarden Secrets CLI (bws)
#
# @param version
#   bws release version.
#   renovate: datasource=github-releases depName=bitwarden/sdk-sm extractVersion=^bws-v(?<version>.+)$
class profile::app::tools::bws (
  String $version = '2.0.0', #renovate: datasource=github-releases depName=bitwarden/sdk-sm extractVersion=^bws-v(?<version>.+)$
) {
  profile::app::binary_install { 'bws':
    version     => $version,
    binary      => 'bws',
    url         => "https://github.com/bitwarden/sdk-sm/releases/download/bws-v${version}/bws-x86_64-unknown-linux-gnu-${version}.zip",
    zip         => true,
    version_cmd => '/usr/local/bin/bws --version | grep -oP "bws \K[\d.]+"',
    install_dir => '/usr/local/bin',
  }
}
