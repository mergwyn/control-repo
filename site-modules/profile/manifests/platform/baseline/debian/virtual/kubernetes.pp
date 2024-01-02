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
# nfs client needed for some services/pods
      stdlib::ensure_packages ( [ 'nfs-common' ], { ensure => present } )

# iscsid is needed for openebs
      package { 'open-iscsi': ensure => present, }
      -> service { 'iscsid':
        ensure => running,
        enable => true,
      }

# Stop import scan service as recommended for openebs
      service { 'zfs-import-scan.service':
        ensure =>  stopped,
        enable => false,
      }
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
