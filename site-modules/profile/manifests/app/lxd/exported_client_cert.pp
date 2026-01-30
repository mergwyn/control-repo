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
  $tmp_cert = "/tmp/lxd-peer-${title}.crt"

  #assert { "lxd_cert_present_${title}":
  #  condition => $cert.unwrap =~ /BEGIN CERTIFICATE/,
  #  message   => "LXD client cert for ${title} is empty or invalid",
  #}

  file { $tmp_cert:
    ensure  => file,
    content => $cert.unwrap,
    mode    => '0644',
  }

  exec { "lxd-trust-${title}":
    path    => ['/usr/bin', '/usr/sbin'],
    command => "lxc config trust add ${tmp_cert} --name ${title}",
    unless  => "lxc config trust list --format=json | jq -e '.[] | select(.name==\"${title}\")' >/dev/null",
    require => File[$tmp_cert],
  }
}
