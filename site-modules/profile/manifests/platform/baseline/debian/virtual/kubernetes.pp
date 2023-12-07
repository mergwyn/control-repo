# @summary Supports either k3s or microk8s kuvernetes variants
#
class profile::platform::baseline::debian::virtual::kubernetes (
  Enum['microk8s','k3s'] $provider = 'k3s',
) {

  if $facts['os']['family'] != 'Debian' {
    fail("${name} can only be called on Debian")
  }

  case ($provider) {
    'k3s': {
      $required_packages = [ 'open-iscsi', 'nfs-common' ]
      stdlib::ensure_packages { $required_packages: }
      # TODO ??
      # TODO sudo systemctl stop zfs-import-scan.service
      # TODO sudo systemctl disable zfs-import-scan.service
    }

    'microk8s': {
      sysctl{ 'net.core.rmem_max':
        ensure => present,
        value  => '2500000',
        target => '/etc/sysctl.d/66-quic.conf',
      }
      sysctl{ 'net.core.wmem_max':
        ensure => present,
        value  => '2500000',
        target => '/etc/sysctl.d/66-quic.conf',
      }
    }

    default: {}
  }

}
