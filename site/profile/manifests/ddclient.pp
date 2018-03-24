#

class profile::ddclient {
  include ddclient
  # package { 'ddclient': ensure => installed }

  #file { '/etc/ddclient.conf':
    #ensure  => file,
    #owner   => root,
    #group   => root,
    #mode    => '0600',
    #require => Package['ddclient'],
    #notify  => Service['ddclient'],
    #source  => 'puppet:///modules/profile/ddclient/ddclient.conf',
  #}

  #service { 'ddclient':
    #ensure    => running,
    #subscribe => [
      #Package['ddclient'],
      #File['/etc/ddclient.conf']
    #],
  #}
}
# vim: sw=2:ai:nu expandtab
