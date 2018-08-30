#
deny duplicates;
allow unknown-clients;
option ntp-servers foxtrot.theclarkhome.com, golf.theclarkhome.com;
use-host-decl-names on;
update-static-leases on;
#option domain-search "theclarkhome.com", "local";
option domain-search "theclarkhome.com";
option ldap-server code 95 = string;
option ldap-server "ldap://theclarkhome.com/dc=theclarkhome,dc=com";
one-lease-per-client on;

default-lease-time 14400;
max-lease-time 86400;
min-lease-time 3600;

# The ddns-updates-style parameter controls whether or not the server will
# attempt to do a DNS update when a lease is confirmed. We default to the
# behavior of the version 2 packages ('none', since DHCP v2 didn't
# have support for DDNS.)
ddns-update-style interim;

key "dhcp-key" {
	algorithm hmac-md5;
	secret "QCYdRi+4rISQPTHhsm2TGw==";
};

# option definitions common to all supported networks...
option domain-name "theclarkhome.com";
option domain-name-servers 192.168.11.22, 192.168.11.21;
option netbios-name-servers 192.168.11.22, 192.168.11.21;

# If this DHCP server is the official DHCP server for the local
authoritative;

# Use this to send dhcp log messages to a different log file (you also
# have to hack syslog.conf to complete the redirection).
log-facility local7;

# zones
zone theclarkhome.com {  
	primary 192.168.11.22; # This server is the primary DNS server for the zone
	key dhcp-key; # Use the key we defined earlier for dynamic updates
}
zone 11.168.192.in-addr.arpa. {  
	primary 192.168.11.22; # This server is the primary DNS server for the zone
	key dhcp-key; # Use the key we defined earlier for dynamic updates
}

subnet 192.168.11.0 netmask 255.255.255.0 {
	authoritative;
	#get-lease-hostnames true;
	ddns-updates off;
	ddns-domainname "theclarkhome.com";
	#ddns-rev-domainname "11.168.192.in-addr.arpa";
	ddns-rev-domainname "in-addr.arpa";
	pool { # needs a pool for the failover stuff
		failover peer "theclarkhome.com";
		range 192.168.11.100 192.168.11.199;
		default-lease-time 14400;
		max-lease-time 86400;
		min-lease-time 3600;
	}

	option routers 192.168.11.254;
}
host netgear-gs108t-1 {
	ddns-hostname "netgear-gs108t-1";
	option host-name "netgear-gs108t-1";
	hardware ethernet 00:8e:f2:59:c7:98;
	fixed-address 192.168.11.1;
}
host netgear-gs116e-1 {
	ddns-hostname "netgear-gs116e-1";
	option host-name "netgear-gs116e-1";
	hardware ethernet a0:40:a0:71:7e:ce;
	fixed-address 192.168.11.2;
}
host zabbix1 {
	hardware ethernet 00:0c:29:95:80:68;
	fixed-address 192.168.11.41;
}
host tango {
	hardware ethernet 00:16:3e:d6:a5:e1;
	fixed-address 192.168.11.42;
}
host s685ip {
	ddns-hostname "s685ip";
	option host-name "s685ip";
	hardware ethernet 00:01:e3:9a:f9:c1;
	fixed-address 192.168.11.43;
}
host echo {
	hardware ethernet 00:16:3e:60:37:e3;
	fixed-address 192.168.11.44;
}
host zulu {
	hardware ethernet 00:16:3e:98:92:d8;
	fixed-address 192.168.11.45;
}
host foxtrot {
	hardware ethernet 00:0c:29:62:d5:5f;
	fixed-address 192.168.11.12;
}
host mike {
	hardware ethernet 52:54:00:53:b7:0a;
	fixed-address 192.168.11.20;
}
host papa {
	hardware ethernet 00:16:3e:fc:2a:87;
	fixed-address 192.168.11.240;
}
host DELLA3F95F {
	ddns-hostname "DELLA3F95F";
	option host-name "DELLA3F95F";
	hardware ethernet 08:00:37:a3:f9:5f;
}
group {
	use-host-decl-names on;
	host humax-lan {
		ddns-hostname "humax";
		option host-name "humax";
		hardware ethernet dc:d3:21:57:55:46;
	}
	host humax {
		ddns-hostname "humax";
		option host-name "humax";
		hardware ethernet 80:1f:02:21:a1:74;
	}

	host SonosZPP-1 {
		ddns-hostname "SonosZPP-1";
		option host-name "SonosZPP-1";
		hardware ethernet  00:0e:58:bc:b4:dc;
	}
	host SonosZP1-1 {
		ddns-hostname "SonosZP1-1";
		option host-name "SonosZP1-1";
		hardware ethernet 00:0e:58:c9:f0:9a;
	}
	host SonosZP1-2 {
		ddns-hostname "SonosZP1-2";
		option host-name "SonosZP1-2";
		hardware ethernet  b8:e9:37:e9:75:f0;
	}
	host SonosZP3-1 {
		option host-name "SonosZP3-1";
		ddns-hostname "SonosZP3-1";
		hardware ethernet 00:0e:58:f8:70:4e;
	}
}

# support for samba4 updates

on commit {
	set noname = concat("dhcp-", binary-to-ascii(10, 8, "-", leased-address));
	set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
	set ClientMac = binary-to-ascii(16, 8, ":", substring(hardware, 1, 6));
	set ClientName = pick-first-value(
		host-decl-name,
		config-option host-name,
		ddns-hostname,
		option host-name,
		noname);
	log(concat("Commit: IP: ", ClientIP, " Mac: ", ClientMac, " Name: ", ClientName));
	#execute("/etc/dhcp/dhcp-dyndns.sh", "add", ClientIP, ClientName, ClientMac);
	execute("/etc/dhcp/dhcpd-update-samba-dns.sh", "add", ClientIP, ClientName, ClientMac);
}
on release {
	set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
	set ClientMac = binary-to-ascii(16, 8, ":", substring(hardware, 1, 6));
	set noname = concat("dhcp-", binary-to-ascii(10, 8, "-", leased-address));
	set ClientName = pick-first-value(
		host-decl-name,
		config-option host-name,
		ddns-hostname,
		option host-name,
		noname);
	log(concat("Release: IP: ", ClientIP, " Mac: ", ClientMac, " Name: ", ClientName));
	#execute("/etc/dhcp/dhcp-dyndns.sh", "delete", ClientIP, ClientName, ClientMac);
	execute("/etc/dhcp/dhcpd-update-samba-dns.sh", "delete", ClientIP, ClientName, ClientMac);
}
on expiry {
	set ClientIP = binary-to-ascii(10, 8, ".", leased-address);
	set ClientMac = binary-to-ascii(16, 8, ":", substring(hardware, 1, 6));
	set noname = concat("dhcp-", binary-to-ascii(10, 8, "-", leased-address));
	set ClientName = pick-first-value(
		host-decl-name,
		config-option host-name,
		ddns-hostname,
		option host-name,
		noname);
	log(concat("Expired: IP: ", ClientIP, " Mac: ", ClientMac, " Name: ", ClientName));
	#execute("/etc/dhcp/dhcp-dyndns.sh", "delete", ClientIP, ClientName, ClientMac);
	execute("/etc/dhcp/dhcpd-update-samba-dns.sh", "delete", ClientIP, ClientName, ClientMac);
}

