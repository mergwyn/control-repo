# @summary Install kube-ps1 shell script for prompt integration
#
class profile::app::kube_ps1 (
  String $version = '0.12.1', # renovate: datasource=github-releases depName:n3kub/kube-ps1
) {
  profile::app::binary_install { 'kube-ps1':
    version     => $version,
    binary      => 'kube-ps1.sh',
    url         => "https://github.com/n3kub/kube-ps1/releases/download/v${version}/kube-ps1.sh",
    tarball     => false,
    stamp       => true,
    install_dir => '/usr/local/share/',
  }
}
