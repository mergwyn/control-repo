# @summary Install and configure remoteit
#
class profile::app::remoteit {

# TODO check if this is the cases
  if $facts['os']['family'] != 'Debian' {
    fail("${title} is only for Debian")
  }

  $version = '4.13.5'
  $url = "https://downloads.remote.it/remoteit/v${version}/remoteit-${version}.amd64.deb"
  package {'remoteit':
    provider => dpkg,
    source   => $url,
  }
}
