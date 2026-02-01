#
#
# profile::app::lxd::remotes
class profile::app::lxd::remotes {
  require profile::platform::baseline::debian::virtual::lxd

  if $facts.dig('lxd', 'manage_remotes') {
    Profile::App::Lxd::Remote <<|
      certname != $trusted['certname']
    |>>
  }
}
