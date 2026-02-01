#
#
#
class profile::app::lxd::remotes {
  require profile::platform::baseline::debian::virtual::lxd

  if $facts.dig('lxd', 'manage_remotes') {

    $client_certs = Profile::App::Lxd::Exported_client_cert <<|
      certname != $trusted['certname']
    |>>

    # Drop anything without a cert (paranoia + old exports)
    $client_certs = $client_certs.filter |$k, $v| { $v['cert'] }

    create_resources(
      'profile::app::lxd::consume_client_cert',
      $client_certs
    )
  }
}
