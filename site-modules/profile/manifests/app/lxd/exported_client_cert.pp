#
#
define profile::app::lxd::exported_client_cert (
  Optional[
    Variant[
      Sensitive[String],
      Sensitive[Deferred]
    ]
  ] $cert,
  String $fqdn,
) {
  if $cert == undef {
    notice("Skipping exported LXD cert for ${title} (no cert yet)")
    return()
  }

  $tmp_cert = "/tmp/lxd-peer-${title}.crt"

  file { $tmp_cert:
    ensure  => file,
    content => $cert.unwrap,
    mode    => '0644',
  }

  exec { "lxd-trust-${title}":
    path    => ['/usr/bin', '/usr/sbin'],
    command => "lxc config trust add ${tmp_cert} --name ${title}",
    unless  => "lxc config trust list --format csv | cut -d, -f1 | grep -qx ${title}",
    require => File[$tmp_cert],
    returns => [0,1],
  }
}
