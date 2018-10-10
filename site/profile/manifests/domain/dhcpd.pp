#
# TODO: move to hiera? use dyanmic resources?

class profile::domian::dhcpd (
  $role = "primary",
  ) {
  $owner = "dhcpd"
  $group = "dhcpd"
  $perms = "$owner.$group"
  $keytab = "/etc/dhcp/dhcpd.keytab"
  package { "isc-dhcp-server": ensure => installed }

  file { "/etc/dhcp/dhcpd.conf":
    ensure  => file,
    require => Package["isc-dhcp-server"],
    notify  => Service["isc-dhcp-server"],
    source  => "puppet:///modules/profile/dhcp/dhcpd.$role.conf",
    owner   => "$owner",
    group   => "$group",
  }

  # export keytab to allow script to run
  exec { 'chown_dhcp_keytab':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    onlyif  => "stat -c '%U.%G' $keytab | grep -v $perms",
    command => "chown $perms $keytab",
  }
  exec { 'export_dhcp_keytab':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    creates => '/etc/dhcp/dhcpd.keytab',
    command => "samba-tool domain exportkeytab \
		$keytab --principal=dhcp",
    notify => Exec['chown_dhcp_keytab'],
  }

  # config files
  file { "/etc/dhcp/dhcpd.$domain":
    ensure  => file,
    require => Package["isc-dhcp-server"],
    notify  => Service["isc-dhcp-server"],
    source  => "puppet:///modules/profile/dhcp/dhcpd.$domain",
    owner   => "$owner",
    group   => "$group",
  }

  file { "/etc/dhcp/dhcp-dyndns-real.sh":
    ensure  => absent,
  }
  file { "/etc/dhcp/dhcp-dyndns.sh":
    ensure  => absent,
  }
#  file { "/etc/dhcp/dhcp-dyndns-real.sh":
#    ensure  => file,
#    mode    => 0755,
#    owner   => 'dhcpd',
#    group   => 'dhcpd',
#    source  => "puppet:///modules/profile/dhcp/dhcp-dyndns-real.sh",
#  }

#  file { "/etc/dhcp/dhcp-dyndns.sh":
#    ensure  => file,
#    mode    => 0755,
#    owner   => 'dhcpd',
#    group   => 'dhcpd',
#    source  => "puppet:///modules/profile/dhcp/dhcp-dyndns.sh",
#  }

  file { "/etc/dhcp/dhcpd-update-samba-dns.conf":
    ensure  => file,
    owner   => "$owner",
    group   => "$group",
    source  => "puppet:///modules/profile/dhcp/dhcpd-update-samba-dns.conf",
  }

  file { "/etc/dhcp/dhcpd-update-samba-dns.sh":
    ensure  => file,
    mode    => '0755',
    owner   => "$owner",
    group   => "$group",
    source  => "puppet:///modules/profile/dhcp/dhcpd-update-samba-dns.sh",
  }

  file { "/etc/dhcp/samba-dnsupdate.sh":
    ensure  => file,
    mode    => '0755',
    owner   => "$owner",
    group   => "$group",
    source  => "puppet:///modules/profile/dhcp/samba-dnsupdate.sh",
  }

  service { "isc-dhcp-server":
    ensure => running,
    subscribe => [
      Package["isc-dhcp-server"],
      File["/etc/dhcp/dhcpd.conf", "/etc/dhcp/dhcpd.$domain"]
    ],
  }

  # need to make sure apparmor is updated to allow the scripts to fire
  include profile::apparmor
  file { "/etc/apparmor.d/local/usr.sbin.dhcpd":
    ensure  => file,
    notify  => Service["apparmor"],
    content  => "  /etc/dhcp/dhcp-dyndns.sh krwux,\n  /etc/dhcp/dhcpd-update-samba-dns.sh krwux, \n",
    owner   => 'root',
    group   => 'root',
  }

}
# vim: sw=2:ai:nu expandtab
