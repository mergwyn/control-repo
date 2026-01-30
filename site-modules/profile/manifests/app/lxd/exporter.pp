#
class profile::app::lxd::exporter {

  if $facts['lxd_client_cert']
    and String($facts['lxd_client_cert']) != '' {

    @@profile::app::lxd::exported_client_cert {
      $facts['networking']['hostname']:
        fqdn => $facts['networking']['fqdn'],
        cert => Sensitive($facts['lxd_client_cert']),
    }
  }
}
