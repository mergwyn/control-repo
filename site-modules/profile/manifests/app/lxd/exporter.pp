#
#
class profile::app::lxd::exporter {
  if $facts['lxd_client_cert_b64']
    and String($facts['lxd_client_cert_b64']) != '' {
    @@profile::app::lxd::exported_client_cert {
      $facts['networking']['hostname']:
        fqdn => $facts['networking']['fqdn'],
        cert => Sensitive(base64('decode', $facts['lxd_client_cert_b64'])),
    }
  }
}
