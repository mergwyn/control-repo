# @summary Supports either k3s or microk8s kuvernetes variants
#
class profile::platform::baseline::debian::virtual::kubernetes (
  Enum['microk8s','k3s'] $provider = 'k3s',
  Boolean $enable_cstor            = false,
  Boolean $enable_mayastor         = false,
  Boolean $enable_longhorn         = false,
) {
  if $facts['os']['family'] != 'Debian' {
    fail("${name} can only be called on Debian")
  }

  case ($provider) {
    'k3s': {
# nfs client needed for some services/pods
      stdlib::ensure_packages (['nfs-common'], { ensure => present })

      # home-assistant now uses the host network and these settings are needed
      # for HA 2026 + K3s HostNetwork Stability
      sysctl { 'net.netfilter.nf_conntrack_tcp_be_liberal':
        ensure => present,
        value  => '1',
        target => '/etc/sysctl.d/99-homeassistant.conf',
      }
      sysctl { 'net.ipv4.ip_local_port_range':
        ensure => present,
        value  => '10240 65000',
        target => '/etc/sysctl.d/99-homeassistant.conf',
      }
      sysctl { 'net.ipv4.tcp_tw_reuse':
        ensure => present,
        value  => '1',
        target => '/etc/sysctl.d/99-homeassistant.conf',
      }
      sysctl { 'net.ipv4.tcp_fin_timeout':
        ensure => present,
        value  => '15',
        target => '/etc/sysctl.d/99-homeassistant.conf',
      }

      # TODO: get the dns names from hiera
      file { '/var/lib/rancher/k3s/server/manifests/coredns-custom.yaml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => @(EOF),
          apiVersion: v1
          kind: ConfigMap
          metadata:
            name: coredns-custom
            namespace: kube-system
          data:
            theclarkhome.server: |
              theclarkhome.com:53 {
                  errors
                  cache 30
                  forward . 10.58.0.21 10.58.0.22
              }
          EOF
      }

# Stop import scan service as recommended for openebs
#      service { 'zfs-import-scan.service':
#        ensure =>  stopped,
#        enable => false,
#      }
    }

    'microk8s': {
      # TODO check what these were for?
      sysctl { 'net.core.rmem_max':
        ensure => present,
        value  => '2500000',
        target => '/etc/sysctl.d/66-quic.conf',
      }
      sysctl { 'net.core.wmem_max':
        ensure => present,
        value  => '2500000',
        target => '/etc/sysctl.d/66-quic.conf',
      }
    }

    default: {}
  }

  file { '/etc/sysctl.d/20-microk8s-hugepages.conf' : ensure => absent }

  if $enable_mayastor {
    sysctl { 'vm.nr_hugepages':
      ensure => present,
      value  => '1536',
      target => '/etc/sysctl.d/21-mayastor.conf',
    }
    kmod::load { 'nvme_tcp': }
  } else {
    file { '/etc/sysctl.d/21-mayastor.conf' : ensure => absent }
    kmod::load { 'nvme_tcp': ensure => absent }
  }

  if $enable_cstor or $enable_longhorn {
    package { 'open-iscsi': ensure => present, }
    -> service { 'iscsid':
      ensure => running,
      enable => true,
    }
  }
}
