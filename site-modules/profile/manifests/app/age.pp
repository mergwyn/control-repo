# profile::app::age
#
class profile::app::age (
  String $version = '1.3.1', # renovate: datasource=github-releases depName=FiloSottile/age
) {
  profile::app::binary_install { 'age':
    version     => $version,
    binary      => 'age',
    url         => "https://github.com/FiloSottile/age/releases/download/v${version}/age-v${version}-linux-amd64.tar.gz",
    tarball     => true,
    tar_extract => 'age/age',
    version_cmd => 'age --version',
  }
}
