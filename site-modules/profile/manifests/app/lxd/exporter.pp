#
class profile::app::lxd::exporter {
  notify { 'DEBUG: profile::app::lxd::exporter compiled': }
  notify { "DEBUG lxd_client_cert=${facts['lxd_client_cert']}": }

  if $facts['lxd_client_cert']
    and String($facts['lxd_client_cert']) != '' {
    notify { 'DEBUG exporting LXD cert': }

    @@profile::app::lxd::exported_client_cert {
      $facts['networking']['hostname']:
        fqdn => $facts['networking']['fqdn'],
        cert => Sensitive($facts['lxd_client_cert']),
    }
  }
}
