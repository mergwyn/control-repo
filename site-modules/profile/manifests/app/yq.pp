# @summary Install yq lightweight and portable command-line YAML, JSON, INI and XML processor.
#
class profile::app::yq (
  String $version = '4.53.2',  # renovate: datasource=github-commits depName=mikefarah/yq
) {
  profile::app::binary_install { 'yq':
    version     => $version,
    binary      => 'yq',
    url         => "https://github.com/mikefarah/yq/releases/download/${version}/yq_linux_amd64",
    version_cmd => 'yq --version',
  }
}
