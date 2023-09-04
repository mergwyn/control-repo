# @summary microk8s support
#
class profile::app::microk8s () {

  if $facts['os']['family'] != 'Debian' {
    fail("${name} can only be called on Debian")
  }

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
