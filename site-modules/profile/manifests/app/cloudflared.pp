# @summary Manages the installation, configuration, and service execution of a remotely-managed Cloudflare Tunnel.
#
# @description This class installs the official Cloudflare `cloudflared` package from upstream repositories,
#   drops the decrypted remote management tunnel token into the configuration directory, and ensures the
#   background system daemon is running. It supports both Debian and RedHat families.
#
# @example Basic usage via profile declaration:
#   class { 'profile::app::cloudflared':
#     tunnel_token   => 'ENC[PKCS7,MIIBiQYJKoZIhvcNAQcDoIIBeT...]',
#     package_ensure => 'present',
#   }
#
# @param tunnel_token
#   The unique, Base64-encoded tunnel token (`eyJ...`) retrieved from the Cloudflare Zero Trust Dashboard
#   for remote configuration. **Note:** This should always be passed as an encrypted `eyaml` block in Hiera.
#
# @param package_ensure
#   Determines the state of the `cloudflared` package. Valid values are 'present', 'latest', or 'absent'.
#   Defaults to 'present'.
#
class profile::app::cloudflared (
  String $tunnel_token,
  String $package_ensure = 'present',
) {
  # 1. Add the Cloudflare Package Repository
  if $facts['os']['family'] == 'Debian' {
    include apt

    apt::source { 'cloudflare':
      ensure   => $package_ensure,
      location => 'https://pkg.cloudflare.com/cloudflared',
      release  => 'any',
      repos    => 'main',
      key      => {
        'name'   => 'cloudflare-main.gpg',
        'source' => 'https://pkg.cloudflare.com/cloudflare-main.gpg',
      },
      before   => Package['cloudflared'],
    }
    apt::key { 'cloudflare-legacy':
      ensure => absent,
      id     => 'CC94B39C77AE7342A68B89628A682D308D4E5E73',
    }

  }

  elsif $facts['os']['family'] == 'RedHat' {
    yumrepo { 'cloudflare':
      ensure   => $package_ensure,
      descr    => 'Cloudflare repo',
      baseurl  => 'https://pkg.cloudflare.com/cloudflared/rpm',
      enabled  => 1,
      gpgcheck => 0,
      before   => Package['cloudflared'],
    }
  }

  # 2. Install the cloudflared package
  package { 'cloudflared':
    ensure  => $package_ensure,
    require => Class['apt::update'],
  }

  # 3. Register the systemd service via 'cloudflared service install'.
  #
  #    Uninstall first if the unit file exists but contains a stale token
  #    (i.e. the token in Hiera has changed). Both onlyif conditions must
  #    be true simultaneously: file present AND current token absent.
  exec { 'cloudflared service uninstall':
    command => '/usr/bin/cloudflared service uninstall',
    onlyif  => "/bin/sh -c 'test -f /etc/systemd/system/cloudflared.service && ! grep -qF \"${tunnel_token}\" /etc/systemd/system/cloudflared.service'",
    require => Package['cloudflared'],
  }

  #    Install (or re-install after token rotation) when the current token
  #    is not already present in the unit file.
  exec { 'cloudflared service install':
    command => "/usr/bin/cloudflared service install ${tunnel_token}",
    unless  => "/usr/bin/grep -qF '${tunnel_token}' /etc/systemd/system/cloudflared.service",
    require => [Package['cloudflared'], Exec['cloudflared service uninstall']],
  }

  # 4. Manage the cloudflared background service
  service { 'cloudflared':
    ensure  => running,
    enable  => true,
    require => Exec['cloudflared service install'],
  }
}
