#
#
define profile::app::lxd::remote (
  String  $fqdn,
  Integer $port = 8443,
) {
  $cert = "/tmp/lxd-${title}.crt"

  exec { "lxd-fetch-cert-${title}":
    command => "echo | openssl s_client -connect ${fqdn}:${port} 2>/dev/null | openssl x509 > ${cert}",
    creates => $cert,
    path    => ['/usr/bin'],
  }

  exec { "lxd-trust-${title}":
    command => "lxc config trust add ${cert} --name ${title}",
    unless  => "lxc config trust list --format=json | jq -e '.[] | select(.name==\"${title}\")'",
    path    => ['/usr/bin:/usr/sbin'],
    require => Exec["lxd-fetch-cert-${title}"],
  }

  exec { "lxd-add-remote-${title}":
    command => "lxc remote add ${title} https://${fqdn}:${port}",
    unless  => "lxc remote list --format csv | cut -d, -f1 | grep -qx ${title}",
    path    => ['/usr/bin:/usr/sbin'],
    require => Exec["lxd-trust-${title}"],
  }
}
