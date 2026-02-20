# @summary Install kubectx shell script with version stamping
#
class profile::app::kubectx (
  String $version = 'f3c2d91', # renovate: datasource=github-commits depName=ahmetb/kubectx
) {
  profile::app::binary_install { 'kubectx':
    version     => $version,
    binary      => 'kubectx',
    url         => "https://github.com/ahmetb/kubectx/raw/${version}/kubectx",
    install_dir => '/usr/local/bin',
    stamp       => true,
  }
}
