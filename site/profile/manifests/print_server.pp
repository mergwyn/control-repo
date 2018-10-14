#

class profile::print_server {
  #include cups::install
  #include cups
  class { 'cups': }

  $dir     = '/usr/share/xerox-driver'
  file { $dir : ensure => directory, }

  $driver = 'xerox-workcentre-6015b-6015n-6015ni'
  $arch =  $::facts['os']['architecture']
  case $arch {
    'i386':  { $version = '1.0-28'; $suffix = $arch }
    'amd64': { $version = '1.0-29'; $suffix = '64'}
    default: { notify { "Unexpected arch ${arch} for print server driver": withpath => true } }
  }
  $package  = "${driver}_${version}_${suffix}.deb"

  file { "${dir}/${package}":
    ensure => present,
    source => "puppet:///modules/profile/print_server/${package}",
  }

  #service { 'cups':
  #  ensure  => 'running',
  #  enable  => true,
  #  require => Package['cups'],
  #}

  package { $driver:
    ensure   => present,
    provider => dpkg,
    require  => Package[ 'cups' ],
    source   => "${dir}/${package}",
  }

  file { '/etc/cups/cupsd.conf':
    ensure => present,
    notify => Service[ 'cups' ],
    source => 'puppet:///modules/profile/print_server/cupsd.conf',
  }

  printer { 'Dell_1355cn_Color_MFP_':
      ensure       => present,
      uri          => 'dnssd://Dell%201355cn%20Color%20MFP%20(A3%3AF9%3A5F)._pdl-datastream._tcp.local/',
      description  => 'DELL Dell 1355cn Color MFP',
      location     => 'Study office',
      model        => 'lsb/usr/Xerox/Xerox-WorkCentre-6015B.ppd.gz',
      shared       => undef,
      error_policy => retry_job, # underscored version of error policy
      enabled      => true, # Enabled by default
      #options      => {  }, # Hash of options ( name => value ), supplied as -o flag to lpadmin.

      # Vendor/driver options
      page_size    => 'A4',
      #color_model  => 'CMYK',  # or 'Gray' usually for grayscale.
      #duplex       => '',

      # AND Any other custom driver specific option...
      #ppd_options  => { 'HPOption_Duplexer' => 'False' }, # Hash of vendor PPD options, set on creation.
  }

  file { '/etc/avahi/services/AirPrint-Dell_1355cn_Color_MFP_.service':
    ensure => present,
    source => 'puppet:///modules/profile/print_server/AirPrint-Dell_1355cn_Color_MFP_.service',
    notify => Service['avahi-daemon'],
  }

}
#
# vim: sw=2:ai:nu expandtab
