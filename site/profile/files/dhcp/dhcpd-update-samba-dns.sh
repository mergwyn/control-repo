#!/bin/bash
# Begin dhcpd-update-dns.sh

. /etc/dhcp/dhcpd-update-samba-dns.conf || exit 1

ACTION=$1
IP=$2
HNAME=$3

export KRB5CC KEYTAB DOMAIN REALM PRINCIPAL NAMESERVER ZONE ACTION IP HNAME

/etc/dhcp/samba-dnsupdate.sh \
	-m \
	--action "$ACTION" \
	--ip "$IP" \
	--hostname "$HNAME" \
	&

# End dhcpd-update-samba-dns.sh
