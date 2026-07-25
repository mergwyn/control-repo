# @summary Configure macOS network time settings.
#
# @param servers
#   NTP servers. Only the first is used; `systemsetup` supports one active server.
#
class profile::platform::baseline::darwin::ntp (
  Array[String] $servers = ['time.apple.com'],
) {
  $primary_server = $servers[0]

  exec { 'enable network time':
    path    => $facts['path'],
    unless  => 'systemsetup -getusingnetworktime | grep -q "On"',
    command => 'systemsetup -setusingnetworktime on',
  }

  exec { 'set network time server':
    path    => $facts['path'],
    onlyif  => "test \"$(systemsetup -getnetworktimeserver | awk '{print \$NF}')\" != \"${primary_server}\"",
    command => "systemsetup -setnetworktimeserver ${primary_server}",
    require => Exec['enable network time'],
  }
}
