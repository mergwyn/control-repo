# @summary Install kube-ps1 shell script for prompt integration
#
class profile::app::kube_ps1 (
  String $version = '8c1a9b4', # renovate: datasource=github-commits depName=jonmosco/kube-ps1
) {
  profile::app::binary_install { 'kube-ps1':
    version     => $version,
    binary      => 'kube-ps1.sh',
    url         => "https://raw.githubusercontent.com/jonmosco/kube-ps1/${version}/kube-ps1.sh",
    install_dir => '/usr/local/share/kube-ps1',
    stamp       => true,
  }
}
