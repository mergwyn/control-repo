#!/bin/bash
# shellcheck disable=SC2001

set -o pipefail
# /usr/local/bin/dhcp-dyndns.sh

# This script is for secure DDNS updates on Samba,
# it can also add the 'macAddress' to the Computers object.
#
# Version: 0.9.1
#
# Copyright (C) Rowland Penny 2020
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

##########################################################################
#                                                                        #
#    You can optionally add the 'macAddress' to the Computers object.    #
#    Add 'dhcpduser' to the 'Domain Admins' group if used                #
#    Change the next line to 'yes' to make this happen                   #
Add_macAddress='no'
#                                                                        #
##########################################################################


log()       { logger -t "dyndns[$$]" "$@" ; }
log_error() { log -p user.error "$@" ; }
log_warn()  { log -p user.warn "$@" ; }
log_notice(){ log -p user.notice "$@" ; }
log_info()  { log -p user.info "$@" ; }
log_debug() { log -p user.debug "$@" ; }
log_debug() { : ; }

usage() {
    echo "USAGE:"
    echo "  $(basename "$0") add ip-address dhcid|mac-address hostname"
    echo "  $(basename "$0") delete ip-address dhcid|mac-address"
}

log_info "DHCP-DNS Update started: $*"

$(grep -E '^[ ]*secondary;' /etc/dhcp/dhcpd.conf > /dev/null) && sleep 15

dhcpduser=dhcp

_KERBEROS () {
# get current time as a number
test=$(date +%d'-'%m'-'%y' '%H':'%M':'%S)

# Check for valid kerberos ticket
log_debug "Running check for valid kerberos ticket"
klist -c "${KRB5CCNAME}" -s
retval="$?"
if [ "$retval" != "0" ]; then
    log_info "Getting new ticket, old one has expired"
    kinit -F -k -t /etc/${dhcpduser}.keytab "${SETPRINCIPAL}"
    retval="$?"
    if [ "$retval" != "0" ]; then
        log_error "dhcpd kinit for dynamic DNS failed with $retval"
        exit 1
    fi
fi
}

printip () {
    local addr
    for (( i=1; i<=$#;i++ )) ; do
	addr="${addr:+$addr.}${!i}" 
    done
    printf $addr
} 2> /dev/null
reverseip () {
    local addr
    for (( i=$#; i>0;i-- )) ; do
	addr="${addr:+$addr.}${!i}" 
    done
    printf $addr
} 2> /dev/null

get_rev_zone_data () {
    local IP="$1"
    local RevZone
    local rzoneip
    local numwords
    readonly rdom='.in-addr.arpa'

    for RevZone in "${_ReverseZones[@]}" ; do
	# Split the rzone
	readarray -d. -t rzoneip < <(printf '%s' "${RevZone%%'.in-addr.arpa'}")
	numwords=${#rzoneip[@]}
	RZIP=$(reverseip ${rzoneip[@]})

	local octets=(${IP//./ })
	ZoneIP=$(printip "${octets[@]:0:${numwords}}" )
	IP2add=$(reverseip ${octets[@]:((numwords)):((4-numwords))})

	if [[ ${ZoneIP} == ${RZIP} ]] ; then
	    log_debug "Reverse zone info found ZoneIP:$ZoneIP, RZIP:$RZIP, IP2add:$IP2add" 
	    printf "%s %s" ${IP2add} ${RevZone}
	    return 0
	fi
    done
    log_warn "Reverse zone info not found for $IP"
    return 1
}

BINDIR=$(samba -b | grep 'BINDIR' | grep -v 'SBINDIR' | awk '{print $NF}')
WBINFO="$BINDIR/wbinfo"

# DHCP Server hostname
Server=$(hostname -s)

# DNS domain
domain=$(hostname -d)
if [ -z "${domain}" ]; then
    log_error "Cannot obtain domain name, is DNS set up correctly?"
    log_error "Cannot continue... Exiting."
    exit 1
fi
# Samba realm
REALM="${domain^^}"

# krbcc ticket cache
export KRB5CCNAME="/tmp/dhcp-dyndns.cc"

# Kerberos principal
SETPRINCIPAL="${dhcpduser}@${REALM}"
# Kerberos keytab : /etc/${dhcpduser}.keytab
# krbcc ticket cache : /tmp/dhcp-dyndns.cc
TESTUSER="$($WBINFO -u | grep ${dhcpduser})"
if [ -z "${TESTUSER}" ]; then
    log_error "No AD dhcp user exists, need to create it first.. exiting."
    log_error "you can do this by typing the following commands"
    log_error "kinit Administrator@${REALM}"
    log_error "samba-tool user create ${dhcpduser} --random-password --description='Unprivileged user for DNS updates via ISC DHCP server'"
    log_error "samba-tool user setexpiry ${dhcpduser} --noexpiry"
    log_error "samba-tool group addmembers DnsAdmins ${dhcpduser}"
    exit 1
fi

# Check for Kerberos keytab
if [ ! -f /etc/${dhcpduser}.keytab ]; then
    log_error "Required keytab /etc/${dhcpduser}.keytab not found, it needs to be created."
    log_error "Use the following commands as root"
    log_error "samba-tool domain exportkeytab --principal=${SETPRINCIPAL} /etc/${dhcpduser}.keytab"
    log_error "chown XXXX:XXXX /etc/${dhcpduser}.keytab"
    log_error "Replace 'XXXX:XXXX' with the user & group that dhcpd runs as on your distro"
    log_error "chmod 400 /etc/${dhcpduser}.keytab"
    exit 1
fi

# Variables supplied by dhcpd.conf
action="$1"
ip="$2"
DHCID="$3"
name="${4%%.*}"

# Exit if no ip address
if [ -z "${ip}" ]; then  
    usage
    exit 1
fi


# Exit if no computer name supplied, unless the action is 'delete'
if [ -z "${name}" ]; then
    if [ "${action}" = "delete" ]; then
        name=$(host -t PTR "${ip}" | awk '{print $NF}' | awk -F '.' '{print $1}')
	if [[ $? != 0 ]] ; then
	    log_error "Name not supllied for delete and unable to find hostname (${name}) for $ip"
	    exit 1
	fi
    else
        usage
        exit 1
    fi
fi

# exit if name contains a space
case ${name} in
  *\ * ) log_error "Invalid hostname '${name}' ...Exiting"
         exit
         ;;
  #  * ) : ;;
esac

# exit if $name starts with 'dhcp'
# if you do not want computers without a hostname in AD
# uncomment the following block of code.
#if [[ ${name} == dhcp* ]]; then
#    log_notice "Not updating DNS record in AD, invalid name ${name}"
#    exit 0
#fi

_KERBEROS
declare -a _ReverseZones
mapfile -t _ReverseZones < <(samba-tool dns zonelist "${Server}" --reverse -d1 | grep 'pszZoneName' | awk '{print $NF}')
if [[ ${#_ReverseZones[@]} = 0 ]]; then
    log_warn "No reverse zone found"
fi

readarray -d ' ' -t newzone < <(get_rev_zone_data ${ip})
log_debug $(declare -p newzone)

declare -i result1=0 result2=0 result3=0 result4=0
## update ##
case "${action}" in
    add)
        # does host have an existing 'A' record ?
        A_REC=$(host -t A "${name}" | awk '{print $NF}')
        # check for dots
        if [[ ${A_REC} == ${ip} ]] ; then
            log_info "A record for ${name} ${ip} does not need to be updated"
        else
            if [[ ${A_REC} == *.* ]]; then
                for curip in ${A_REC} ; do
                    log_info "Found A record, deleting ${name} A ${curip}"
                    samba-tool dns delete "${Server}" "${domain}" "${name}" A "${curip}" -k yes -d 0
                done
                (( result1 += "$?" ))
            fi
            log_notice "adding ${name} A ${ip}"
            samba-tool dns add "${Server}" "${domain}" "${name}" A "${ip}" -k yes -d 1
            (( result2 += "$?" ))
        fi

        # get existing reverse zones (if any)
        if [ -z "$_ReverseZones" ]; then
            log_info "No reverse zone found, not updating"
        else
            current_name=$(host -t PTR "${ip}" | cut -d " " -f 5)
            current_name=${current_name::-1} # Last character is a period and needs to be stripped
            if [[ ${name}.${domain} == ${current_name} ]] ; then
                log_info "PTR record for ${name} ${ip} does not need to be updated"
            else
		if [[ ${A_REC} != *.* ]]; then
		    A_REC=${ip}
		fi
                # Take care of deleting, checking for a previous IP in different rzone
                for curip in ${A_REC} ; do
		    readarray -d ' ' -t oldzone < <(get_rev_zone_data ${curip})
		    log_debug $(declare -p oldzone)
		    IP2add=${oldzone[0]}
		    revzone=${oldzone[1]}
		    log_info "Found PTR record, deleting ${IP2add} PTR ${name}.${domain} from ${revzone}"
		    samba-tool dns delete "${Server}" "${revzone}" "${IP2add}" PTR "${name}.${domain}" -k yes -d 1
		    (( result3 += "$?" ))
                done
		IP2add=${newzone[0]}
		revzone=${newzone[1]}
		log_info "Adding ${IP2add} PTR ${name}.${domain} to ${revzone}"
		samba-tool dns add "${Server}" "${revzone}" "${IP2add}" PTR "${name}.${domain}" -k yes -d 1
		(( result4 += "$?" ))
            fi
        fi
        ;;
 delete)
        log_info "Deleting ${name} A ${ip}"
        samba-tool dns delete "${Server}" "${domain}" "${name}" A "${ip}" -k yes -d 1
        (( result1 += "$?" ))
        # get existing reverse zones (if any)
        if [ -z "$_ReverseZones" ]; then
            log_error "No reverse zone found, not updating"
        else
	    IP2add=${newzone[0]}
	    revzone=${newzone[1]}
	    log_info "Deleting ${IP2add} PTR ${name}.${domain} from ${revzone}"
	    samba-tool dns delete "${Server}" "${revzone}" "${IP2add}" PTR "${name}.${domain}" -k yes -d 1
	    (( result2 += "$?" ))
        fi
        ;;
      *)
        log_error "Invalid action specified"
        exit 103
        ;;
esac

result="${result1}:${result2}:${result3}:${result4}"

if [ "${result}" != "0:0:0:0" ]; then
    log_error "DHCP-DNS Update failed: ${result}"
    exit 1
else
    log_notice "DHCP-DNS Update succeeded"
fi
 
if [ "$Add_macAddress" != 'no' ]; then
    if [ -n "$DHCID" ]; then
        Computer_Object=$(ldbsearch -k yes -H ldap://"$Server" "(&(objectclass=computer)(objectclass=ieee802Device)(cn=$name))" | grep -v '#' | grep -v 'ref:')
        if [ -z "$Computer_Object" ]; then
            # Computer object not found with the 'ieee802Device' objectclass, does the computer actually exist, it should.
            Computer_Object=$(ldbsearch -k yes -H ldap://"$Server" "(&(objectclass=computer)(cn=$name))" | grep -v '#' | grep -v 'ref:')
            if [ -z "$Computer_Object" ]; then
                log_error "Computer '$name' not found. Exiting."
                exit 68
            else
                DN=$(echo "$Computer_Object" | grep 'dn:')
                objldif="$DN
changetype: modify
add: objectclass
objectclass: ieee802Device"

                attrldif="$DN
 changetype: modify
add: macAddress
macAddress: $DHCID"

                # add the ldif
                echo "$objldif" | ldbmodify -k yes -H ldap://"$Server"
                ret="$?"
                if [ "$ret" -ne 0 ]; then
                    log_error "Error modifying Computer objectclass $name in AD."
                    exit "${ret}"
                fi
                sleep 2
                echo "$attrldif" | ldbmodify -k yes -H ldap://"$Server"
                ret="$?"
                if [ "$ret" -ne 0 ]; then
                    log_error "Error modifying Computer attribute $name in AD."
                    exit "${ret}"
                fi
                unset objldif
                unset attrldif
                log_notice "Successfully modified Computer $name in AD"
            fi
        else
            DN=$(echo "$Computer_Object" | grep 'dn:')
            attrldif="$DN
changetype: modify
replace: macAddress
macAddress: $DHCID"

            echo "$attrldif" | ldbmodify -k yes -H ldap://"$Server"
            ret="$?"
            if [ "$ret" -ne 0 ]; then
                log_error "Error modifying Computer attribute $name in AD."
                exit "${ret}"
            fi
            unset attrldif
            log_notice "Successfully modified Computer $name in AD"
        fi
    else
        # $DHCID not set
        log_error "Error: DHCID not supplied, required to store in AD."
        usage
        exit 1
    fi
fi

exit 0

# vim: sw=4
