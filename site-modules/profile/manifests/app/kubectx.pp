# @summary Install kubectx/kubensshell script with version stamping
#
class profile::app::kubectx (
  String $version = '013b6bc252ea6bbe7c8372ed64c327ad8a52f003', # renovate: datasource=github-commits depName=ahmetb/kubectx
) {
  profile::app::binary_install { 'kubectx':
    version     => $version,
    binary      => 'kubectx',
    url         => "https://github.com/ahmetb/kubectx/raw/${version}/kubectx",
    install_dir => '/usr/local/bin',
    stamp       => true,
  }

  profile::app::binary_install { 'kubens':
    version     => $version,
    binary      => 'kubens',
    url         => "https://github.com/ahmetb/kubens/raw/${version}/kubens",
    install_dir => '/usr/local/bin',
    stamp       => true,
  }
}
