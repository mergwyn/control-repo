#
#
define profile::app::lxd::consume_client_cert (
  String $fqdn,
  Sensitive[String] $cert,
) {
  $cert_string = $cert.unwrap

  if $cert_string !~ /BEGIN CERTIFICATE/ {
    fail("Invalid LXD client cert for ${title}")
  }

  $tmp_cert = "/tmp/lxd-peer-${title}.crt"

  file { $tmp_cert:
    ensure  => file,
    content => $cert_string,
    mode    => '0644',
  }

  exec { "lxd-trust-${title}":
    path    => ['/usr/bin', '/usr/sbin'],
    command => "lxc config trust add ${tmp_cert} --name ${title}",
    unless  => "lxc config trust list --format=json | jq -e '.[] | select(.name==\"${title}\")' >/dev/null",
    require => File[$tmp_cert],
  }
}
