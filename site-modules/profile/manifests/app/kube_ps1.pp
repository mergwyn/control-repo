# @summary Install kube-ps1 shell script for prompt integration
#
class profile::app::kube_ps1 (
  String $version = '9b41c091d5dd4a99e58cf58b5d98a4847937b1bb', # renovate: datasource=github-commits depName=jonmosco/kube-ps1
) {
  profile::app::binary_install { 'kube-ps1':
    version     => $version,
    binary      => 'kube-ps1.sh',
    url         => "https://raw.githubusercontent.com/jonmosco/kube-ps1/${version}/kube-ps1.sh",
    install_dir => '/usr/local/share/kube-ps1',
    stamp       => true,
  }
}
