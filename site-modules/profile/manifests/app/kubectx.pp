#
#
class profile::app::kubectx (
  String $version = '0.9.5', # renovate: datasource=github-releases depName=ahmetb/kubectx
) {
  profile::app::binary_install { 'kubectx':
    version     => $version,
    binary      => 'kubectx',
    url         => "https://github.com/ahmetb/kubectx/releases/download/v${version}/kubectx_v${version}_linux_x86_64.tar.gz",
    tarball     => true,
    tar_extract => 'kubectx',
  }
}
