#
#
define profile::app::lxd::exported_client_cert (
  String $fqdn,
  Optional[
    Variant[
      Sensitive[String],
      Sensitive[Deferred]
    ]
  ] $cert = undef,
) {
  if ! $trusted {
    notify { "LXD trust not bootstrapped yet on ${facts['networking']['hostname']}": }
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
    unless  => "lxc config trust list --format=json | jq -e '.[] | select(.name==\"${title}\")'",
    require => File[$tmp_cert],
    returns => [0,1],
  }
}
