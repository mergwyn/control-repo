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
      location => 'https://pkg.cloudflare.com/',
      release  => $facts['os']['distro']['codename'],
      repos    => 'main',
      key      => {
        'id'     => '9CF8C2E689C8F6CD8E1E5E4E3C1A1A5D241E7A31',
        'source' => 'https://pkg.cloudflare.com/cloudflare-main.gpg',
      },
      before   => Package['cloudflared'],
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
    ensure => $package_ensure,
  }

  # 3. Create the configuration directory
  file { '/etc/cloudflared':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Package['cloudflared'],
  }

  # 4. Inject the Remotely Managed Tunnel Token
  file { '/etc/cloudflared/config.yml':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => "tunnel: ${tunnel_token}\n",
    require => File['/etc/cloudflared'],
    notify  => Service['cloudflared'],
  }

  # 5. Manage the cloudflared background service
  service { 'cloudflared':
    ensure    => running,
    enable    => true,
    subscribe => File['/etc/cloudflared/config.yml'],
  }
}
