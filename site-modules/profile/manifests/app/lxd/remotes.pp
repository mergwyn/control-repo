#
class profile::app::lxd::remotes {
  require profile::platform::baseline::debian::virtual::lxd

  if $facts['lxd']['manage_remotes'] {
    Profile::App::Lxd::Remote <<| |>> {
      unless => "lxc remote list --format csv | cut -d, -f1 | grep -qx ${title}",
    }
  }
}
