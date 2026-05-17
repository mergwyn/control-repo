# @summary Install kubectx/kubensshell script with version stamping
#
class profile::app::kubectx (
  String $version = '013b6bc252ea6bbe7c8372ed64c327ad8a52f003', # renovate: datasource=github-commits depName=ahmetb/kubectx
) {
  $url = "https://github.com/ahmetb/kubectx/raw/${version}/"
  $bin_dir = "/usr/local/bin"

  profile::app::binary_install { 'kubectx':
    version     => $version,
    binary      => 'kubectx',
    url         => "${url}/kubectx",
    install_dir => $bin_dir,
    stamp       => true,
  }

  profile::app::binary_install { 'kubens':
    version     => $version,
    binary      => 'kubens',
    url         => "${url}/kubens",
    install_dir => $bin_dir,
    stamp       => true,
  }
}
