#
class profile::app::lxd::remotes {
  require profile::platform::baseline::debian::virtual::lxd

  if $facts['lxd']
    and $facts['lxd']['manage_remotes'] {
    Profile::App::Lxd::Remote <<| |>>
    Profile::App::Lxd::Exported_client_cert <<| |>>
  }
}
