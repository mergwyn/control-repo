#
#
class profile::app::dhcpd (
  Optional[Enum['primary','secondary']] $role         = undef,
  Optional[Stdlib::IP::Address]         $peer_address = undef,
  ) {
  $owner = 'dhcpd'
  $group = 'dhcpd'
  $perms = "${owner}.${group}"
  $keytab = '/etc/dhcp.keytab'


  # Core dhcpd configuration
  $domain = $trusted['domain']

  class { 'dhcp':
    interfaces         => [ $facts['networking']['primary'] ],
    nameservers        => lookup('defaults::dns::nameservers'),
    ntpservers         => [ "foxtrot.${domain}", "golf.${domain}" ],
    dnssearchdomains   => lookup('defaults::dns::search'),
    default_lease_time => 28800,
    max_lease_time     => 86400,
    extra_config       => [
      'min-lease-time 3600;',
      'include "/etc/dhcp/dhcpd.samba_ddns";',
    ],
  }

  dhcp::pool { lookup('defaults::network'):
    network  => lookup('defaults::network'),
    mask     => lookup('defaults::netmask'),
    range    => [ "${lookup('defaults::subnet')}.100 ${lookup('defaults::subnet')}.199" ],
    gateway  => lookup('defaults::gateway'),
    failover => 'dhcp-failover',
  }
  if ($role and $peer_address) {
    class { 'dhcp::failover':
      role         => $role,
      peer_address => $peer_address,
      port         => 647,
      #mclt         => 3600,
      load_split   => 128,
    }
  }

# Hosts with fixed ip
  dhcp::host { 'WS_DLG': mac => '04:ee:e8:1a:64:d2' , ip => '10.58.0.200' }
  dhcp::host { 'WS_GWY': mac => '04:ee:e8:1f:68:73' , ip => '10.58.0.201' }

# Hosts that just need names,
  #dhcp::host { 'switch1':               mac => '00:8e:f2:59:c7:98' }
  dhcp::host { 'switch2':               mac => 'a0:40:a0:71:7e:ce' }
  #dhcp::host { 'cisco1':                mac => '5c:50:15:52:47:40' }
  dhcp::host { 'hp1810':                mac => 'd4:c9:ef:37:ca:e0' }
  #dhcp::host { 'cisco1':                mac => '5C:50:15:52:47:00' }
  #dhcp::host { 'DELLA3F95F':            mac => '08:00:37:a3:f9:5f' }
  #dhcp::host { 's685ip':                mac => '00:01:e3:9a:f9:c1' }
  dhcp::host { 'robovac':               mac => '80:7d:3a:3b:67:3c' }
  dhcp::host { 'humax-wifi':            mac => '80:1f:02:21:a1:74' }
  dhcp::host { 'humax-lan':             mac => 'dc:d3:21:57:55:46' }
  dhcp::host { 'lounge-sonos-playbar':  mac => '00:0e:58:bc:b4:dc' }
  dhcp::host { 'lounge-sonos-play1-ls': mac => '00:0e:58:c9:f0:9a' }
  dhcp::host { 'lounge-sonos-play1-rs': mac => '94:9F:3E:12:FA:8A' }
  dhcp::host { 'kitchen-sonos-playone': mac => '78:28:CA:CB:8B:94' }
  dhcp::host { 'bedroom-HS100':         mac => '0C:80:63:0C:40:16' }
  dhcp::host { 'lounge-HS100':          mac => 'D8:0D:17:56:A3:DC' }

# Hosts with different gateway (VPN)
# TODO move vpn hosts to new VLAN
  profile::app::dhcpd::vpnhost { 'india': mac => '00:16:3e:93:c6:21', }
  profile::app::dhcpd::vpnhost { 'tango': mac => '00:16:3e:01:f8:9a', ip => '10.58.0.30', }
  profile::app::dhcpd::vpnhost { 'kilo':  mac => '00:16:3e:5c:39:e0', }

# export keytab to allow script to run
  exec { 'chown_dhcp_keytab':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    onlyif  => "stat -c '%U.%G' ${keytab} | grep -v ${perms}",
    command => "chown ${perms} ${keytab}",
  }
  exec { 'export_dhcp_keytab':
    path    => '/bin:/sbin:/usr/bin:/usr/sbin',
    creates => $keytab,
    command => "samba-tool domain exportkeytab \
		${keytab} --principal=dhcp",
    notify  => Exec['chown_dhcp_keytab'],
  }
  $noname = 'set noname = concat("dhcp-", binary-to-ascii(10, 8, "-", leased-address))'
  $clientip = 'set ClientIP = binary-to-ascii(10, 8, ".", leased-address)'
  $clientdhcid = @(EOT)
    set ClientDHCID = concat (
        suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,1,1))),2), ":",
        suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,2,1))),2), ":",
        suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,3,1))),2), ":",
        suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,4,1))),2), ":",
        suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,5,1))),2), ":",
        suffix (concat ("0", binary-to-ascii (16, 8, "", substring(hardware,6,1))),2)
      )
    | -EOT
  $clientname = @(EOT)
    set ClientName = pick-first-value(
        ddns-hostname,
        host-decl-name,
        option host-name,
        config-option-host-name,
        client-name, noname
      )
    | -EOT

  # config files
  file { '/etc/dhcp/dhcpd.samba_ddns':
    ensure  => file,
    require => Package['isc-dhcp-server'],
    notify  => Service['isc-dhcp-server'],
    owner   => $owner,
    group   => $group,
    content => @("EOT")
               on commit {
                 ${noname};
                 ${clientip};
                 ${clientdhcid};
                 ${clientname};
                 log(concat("Commit: IP: ", ClientIP, " DHCID: ", ClientDHCID, " Name: ", ClientName));
                 execute("/etc/dhcp/dhcp-dyndns.sh", "add", ClientIP, ClientDHCID, ClientName);
               }
 
               on release {
                 ${noname};
                 ${clientip};
                 ${clientdhcid};
                 ${clientname};
                 log(concat("Release: IP: ", ClientIP));
                 execute("/etc/dhcp/dhcp-dyndns.sh", "delete", ClientIP, ClientDHCID, ClientName);
               }
 
               on expiry {
                 ${clientip};
                 # cannot get a ClientMac here, apparently this only works when actually receiving a packet
                 log(concat("Expired: IP: ", ClientIP));
                 # cannot get a ClientName here, for some reason that always fails
                 # however the dhcp update script will obtain the short hostname.
                 execute("/etc/dhcp/dhcp-dyndns.sh", "delete", ClientIP, "dummymac");
               }
               | EOT
  }

  file { '/etc/dhcp/dhcp-dyndns.sh':
    ensure => file,
    owner  => $owner,
    group  => $group,
    mode   => '0755',
    source => 'puppet:///modules/profile/dhcp/dhcp-dyndns.sh',
  }

  file { '/etc/dhcp/dhcpd-update-samba-dns.conf': ensure => absent }
  file { '/etc/dhcp/dhcpd-update-samba-dns.sh':   ensure => absent }
  file { '/etc/dhcp/samba-dnsupdate.sh':          ensure => absent }

  # need to make sure apparmor is updated to allow the scripts to fire
  include profile::platform::baseline::debian::apparmor
  file { '/etc/apparmor.d/local/usr.sbin.dhcpd':
    ensure  => file,
    notify  => Service['apparmor'],
    owner   => 'root',
    group   => 'root',
    content => @("EOT")
               / r,
               /bin/date rix,
               /bin/egrep rix,
               /bin/grep rix,
               /bin/hostname rix,
               /bin/sed rix,
               /bin/sleep rix,
               /bin/uname rix,
               /dev/tty wr,
               /dev/urandom w,
               /etc/dhcp/dhcp-dyndns.sh rix,
               /etc/dhcp.keytab rk,
               /proc/** r,
               /run/samba/winbindd/pipe wr,
               /tmp/dhcp-dyndns.cc rwk,
               /usr/bin/cut rix,
               /usr/bin/date rix,
               /usr/bin/egrep rix,
               /usr/bin/grep rix,
               /usr/bin/heimtools rix,
               /usr/bin/hostname rix,
               /usr/bin/host rix,
               /usr/bin/kinit rix,
               /usr/bin/kinit w,
               /usr/bin/klist rix,
               /usr/bin/logger rix,
               /usr/bin/mawk rix,
               /usr/bin/tr rix,
               /usr/bin/ r,
               /usr/bin/samba-tool rix,
               /usr/bin/sed rix,
               /usr/bin/sleep rix,
               /usr/bin/uname rix,
               /usr/bin/wbinfo rix,
               /usr/local/lib/${facts['python3_release']}/dist-packages r,
               /usr/local/lib/${facts['python3_release']}/dist-packages/ r,
               /usr/local/lib/python${facts['python3_release']}/dist-packages r,
               /usr/local/lib/python${facts['python3_release']}/dist-packages/ r,
               /usr/sbin/samba rix,
               /var/lib/samba/private/krb5.conf r,
               /var/lib/sss/pubconf/kdcinfo.* r,

               | EOT
  }

}
