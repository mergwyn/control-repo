#!/bin/bash
# shellcheck disable=SC2001

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

usage() {
echo "USAGE:"
echo "  $(basename "$0") add ip-address dhcid|mac-address hostname"
echo "  $(basename "$0") delete ip-address dhcid|mac-address"
}


dhcpduser=dhcp

_KERBEROS () {
# get current time as a number
test=$(date +%d'-'%m'-'%y' '%H':'%M':'%S)

# Check for valid kerberos ticket
#logger "${test} [dyndns] : Running check for valid kerberos ticket"
klist -c "${KRB5CCNAME}" -s
retval="$?"
if [ "$retval" != "0" ]; then
    logger "${test} [dyndns] : Getting new ticket, old one has expired"
    kinit -F -k -t /etc/${dhcpduser}.keytab "${SETPRINCIPAL}"
    retval="$?"
    if [ "$retval" != "0" ]; then
        logger "${test} [dyndns] : dhcpd kinit for dynamic DNS failed"
        exit 1
    fi
fi
}

rev_zone_info () {
    local RevZone="$1"
    local IP="$2"
    local rzoneip
    rzoneip=$(echo "$RevZone" | sed 's/\.in-addr.arpa//')
    local rzonenum
    rzonenum=$(echo "$rzoneip" | sed 's/\./ /g')
    local words=($rzonenum)
    local numwords="${#words[@]}"
    echo Got $numwords
    case "$numwords" in
        1) # single ip rev zone '192'
           ZoneIP=$(echo "${IP}" | awk -F '.' '{print $1}')
           RZIP=$(echo "${rzoneip}" | awk -F '.' '{print $3}')
           IP2add=$(echo "${IP}" | awk -F '.' '{print $4"."$3"."$2}')
           ;;
        2) # double ip rev zone '168.192'
           ZoneIP=$(echo "${IP}" | awk -F '.' '{print $1"."$2}')
           RZIP=$(echo "${rzoneip}" | awk -F '.' '{print $2"."$1}')
           IP2add=$(echo "${IP}" | awk -F '.' '{print $4"."$3}')
           ;;
        3) # triple ip rev zone '0.168.192'
           ZoneIP=$(echo "${IP}" | awk -F '.' '{print $1"."$2"."$3}')
           RZIP=$(echo "${rzoneip}" | awk -F '.' '{print $3"."$2"."$1}')
           IP2add=$(echo "${IP}" | awk -F '.' '{print $4}')
           ;;
        *) # should never happen
           exit 1
           ;;
    esac
    echo "$ZoneIP"
    echo "$RZIP"
    echo "$IP2add" 

}

BINDIR=$(samba -b | grep 'BINDIR' | grep -v 'SBINDIR' | awk '{print $NF}')
WBINFO="$BINDIR/wbinfo"

# DHCP Server hostname
Server=$(hostname -s)

# DNS domain
domain=$(hostname -d)
if [ -z "${domain}" ]; then
    logger "Cannot obtain domain name, is DNS set up correctly?"
    logger "Cannot continue... Exiting."
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
    logger "No AD dhcp user exists, need to create it first.. exiting."
    logger "you can do this by typing the following commands"
    logger "kinit Administrator@${REALM}"
    logger "samba-tool user create ${dhcpduser} --random-password --description='Unprivileged user for DNS updates via ISC DHCP server'"
    logger "samba-tool user setexpiry ${dhcpduser} --noexpiry"
    logger "samba-tool group addmembers DnsAdmins ${dhcpduser}"
    exit 1
fi

# Check for Kerberos keytab
if [ ! -f /etc/${dhcpduser}.keytab ]; then
    echo "Required keytab /etc/${dhcpduser}.keytab not found, it needs to be created."
    echo "Use the following commands as root"
    echo "samba-tool domain exportkeytab --principal=${SETPRINCIPAL} /etc/${dhcpduser}.keytab"
    echo "chown XXXX:XXXX /etc/${dhcpduser}.keytab"
    echo "Replace 'XXXX:XXXX' with the user & group that dhcpd runs as on your distro"
    echo "chmod 400 /etc/${dhcpduser}.keytab"
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
    else
        usage
        exit 1
    fi
fi

# exit if name contains a space
case ${name} in
  *\ * ) logger "Invalid hostname '${name}' ...Exiting"
         exit
         ;;
  #  * ) : ;;
esac

# exit if $name starts with 'dhcp'
# if you do not want computers without a hostname in AD
# uncomment the following block of code.
#if [[ $name == dhcp* \]]; then
#    logger "not updating DNS record in AD, invalid name"
#    exit 0
#fi

## update ##
case "${action}" in
    add)
        _KERBEROS

        # does host have an existing 'A' record ?
        A_REC=$(host -t A "${name}" | awk '{print $NF}')
        # check for dots
        if [[ $A_REC == *.* ]]; then
            samba-tool dns delete "${Server}" "${domain}" "${name}" A "${ip}" -k yes
            result1="$?"
        else
            result1=0
        fi
        samba-tool dns add "${Server}" "${domain}" "${name}" A "${ip}" -k yes
        result2="$?"

        # get existing reverse zones (if any)
        ReverseZones=$(samba-tool dns zonelist "${Server}" --reverse | grep 'pszZoneName' | awk '{print $NF}')
        if [ -z "$ReverseZones" ]; then
            echo "No reverse zone found, not updating"
            result3='0'
            result4='0'
        else
            for revzone in $ReverseZones
            do
              rev_zone_info "$revzone" "${ip}"
              if [[ ${ip} = $ZoneIP* ]] && [ "$ZoneIP" = "$RZIP" ]; then
                  host -t PTR "${ip}" > /dev/null 2>&1
                  retval="$?"
                  if [ "$retval" -eq 0 ]; then
                      samba-tool dns delete "${Server}" "${revzone}" "${IP2add}" PTR "${name}.${domain}" -k yes
                      result3="$?"
                  else
                      result3='0'
                  fi
                  samba-tool dns add "${Server}" "${revzone}" "${IP2add}" PTR "${name}.${domain}" -k yes
                  result4="$?"
                  break
              else
                  continue
              fi
            done
        fi
        ;;
 delete)
        _KERBEROS

        samba-tool dns delete "${Server}" "${domain}" "${name}" A "${ip}" -k yes
        result1="$?"
        # get existing reverse zones (if any)
        ReverseZones=$(samba-tool dns zonelist "${Server}" --reverse | grep 'pszZoneName' | awk '{print $NF}')
        if [ -z "$ReverseZones" ]; then
            logger "No reverse zone found, not updating"
            result2='0'
        else
            for revzone in $ReverseZones
            do
              rev_zone_info "$revzone" "${ip}"
              if [[ ${ip} = $ZoneIP* ]] && [ "$ZoneIP" = "$RZIP" ]; then
                  host -t PTR "${ip}" > /dev/null 2>&1
                  retval="$?"
                  if [ "$retval" -eq 0 ]; then
                      samba-tool dns delete "${Server}" "${revzone}" "${IP2add}" PTR "${name}.${domain}" -k yes
                      result2="$?"
                  else
                      result2='0'
                  fi
                  break
              else
                  continue
              fi
            done
        fi
        result3='0'
        result4='0'
        ;;
      *)
        logger "Invalid action specified"
        exit 103
        ;;
esac

result="${result1}:${result2}:${result3}:${result4}"

if [ "${result}" != "0:0:0:0" ]; then
    logger "DHCP-DNS Update failed: ${result}"
    exit 1
else
    logger "DHCP-DNS Update succeeded"
fi
 
if [ "$Add_macAddress" != 'no' ]; then
    if [ -n "$DHCID" ]; then
        Computer_Object=$(ldbsearch -k yes -H ldap://"$Server" "(&(objectclass=computer)(objectclass=ieee802Device)(cn=$name))" | grep -v '#' | grep -v 'ref:')
        if [ -z "$Computer_Object" ]; then
            # Computer object not found with the 'ieee802Device' objectclass, does the computer actually exist, it should.
            Computer_Object=$(ldbsearch -k yes -H ldap://"$Server" "(&(objectclass=computer)(cn=$name))" | grep -v '#' | grep -v 'ref:')
            if [ -z "$Computer_Object" ]; then
                logger "Computer '$name' not found. Exiting."
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
                    logger "Error modifying Computer objectclass $name in AD."
                    exit "${ret}"
                fi
                sleep 2
                echo "$attrldif" | ldbmodify -k yes -H ldap://"$Server"
                ret="$?"
                if [ "$ret" -ne 0 ]; then
                    logger "Error modifying Computer attribute $name in AD."
                    exit "${ret}"
                fi
                unset objldif
                unset attrldif
                logger "Successfully modified Computer $name in AD"
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
                logger "Error modifying Computer attribute $name in AD."
                exit "${ret}"
            fi
            unset attrldif
            logger "Successfully modified Computer $name in AD"
        fi
    else
        # $DHCID not set
        logger "Error: DHCID not supplied, required to store in AD."
        usage
        exit 1
    fi
fi

exit 0

# vim: sw=4
