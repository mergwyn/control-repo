#
#
#
class profile::app::lxd::remotes {
  require profile::platform::baseline::debian::virtual::lxd

  if $facts.dig('lxd', 'manage_remotes') {
    Profile::App::Lxd::Exported_client_cert <<|
      certname != $trusted['certname']
    |>>
  }
}
