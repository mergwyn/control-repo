#
#
define profile::app::lxd::remote (
  String $fqdn,
  Integer $port = 8443,
) {
  # Skip self
  if $title != $facts['networking']['hostname'] {
    exec { "lxd-add-remote-${title}":
      path    => ['/usr/bin', '/usr/sbin'],
      command => "lxc remote add ${title} https://${fqdn}:${port}",
      unless  => "lxc remote list --format csv | cut -d, -f1 | grep -qx ${title}",
      timeout => 60,
    }
  }
}
