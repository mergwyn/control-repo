# @Summary Install the Bitwarden Secrets Manager CLI
#
class profile::app::tools::bws (
  String $version = '2.1.0', # renovate: datasource=github-releases depName=bitwarden/sdk-sm extractVersion=^bws-v(?<version>.*)$
) {
  profile::app::binary_install { 'bws':
    version         => $version,
    binary          => 'bws',
    url             => "https://github.com/bitwarden/sdk-sm/releases/download/bws-v${version}/bws-x86_64-unknown-linux-gnu-${version}.zip",
    archive         => 'zip',
    archive_extract => 'bws',
    version_cmd     => 'bws --version',
  }
}
