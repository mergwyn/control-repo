#!/bin/bash
#
# Begin samba-dnsupdate.sh
# Author: DJ Lucas <dj_AT_linuxfromscratch_DOT_org>
# kerberos_creds() courtesy of Sergey Urushkin
# http://www.kuron-germany.de/michael/blog/wp-content/uploads/2012/03/dhcpdns-sergey2.txt

# DHCP server should be authoritative for its own records, sleep for 5 seconds
# to allow unconfigured Windows hosts to create their own DNS records
# In order to use this script you should disable dynamic updates by hosts that
# will receive addresses from this DHCP server. Instructions are found here:
# https://wiki.archlinux.org/index.php/Samba_4_Active_Directory_Domain_Controller#DHCP

log()       { logger -t "dhcpd[$$]" "$@" ; }
log_error() { log -p daemon.error "$@" ; }
log_info()  { log -p daemon.info "$@" ; }

log_info "$(basename $0): $*"

SLEEPTIME=5
$(egrep '^[ ]*secondary;' /etc/dhcp/dhcpd.conf > /dev/null) && SLEEPTIME=20
sleep "$SLEEPTIME"

checkvalues() {
  [ -z "${2}" ] && log_error -s "Error: argument '${1}' requires a parameter." && exit 1
  case ${2} in
    -*) log_error -s "Error: Invalid parameter '${2}' passed to ${1}."
        exit 1 ;;
    *)  return 0 ;;
  esac
}

showhelp() {
  echo -e "\n"`basename ${0}` "uses samba-tool to update DNS records in Samba 4's DNS"
  echo "server when using INTERNAL DNS or BIND9 DLZ plugin."
  echo ""
  echo "    Command line options (and variables):"
  echo ""
  echo "      -a | --action      Action for this script to perform"
  echo "                         ACTION={add|delete}"
  echo "      -c | --krb5cc      Path of the krb5 credential cache (optional)"
  echo "                         Default: KRB5CC=/run/dhcpd.krb5cc"
  echo "      -d | --domain      The DNS domain/zone to be updated"
  echo "                         DOMAIN={domain.tld}"
  echo "      -h | --help        Show this help message and exit"
  echo "      -H | --hostname    Hostname of the record to be updated"
  echo "                         HNAME={hostname}"
  echo "      -i | --ip          IP address of the host to be updated"
  echo "                         IP={0.0.0.0}"
  echo "      -k | --keytab      Krb5 keytab to be used for authorization (optional)"
  echo "                         Default: KEYTAB=/etc/dhcp/dhcpd.keytab"
  echo "      -m | --mitkrb5     Use MIT krb5 client utilities"
  echo "                         MITKRB5={YES|NO}"
  echo "      -n | --nameserver  DNS server to be updated (must use FQDN, not IP)"
  echo "                         NAMESERVER={server.internal.domain.tld}"
  echo "      -p | --principal   Principal used for DNS updates"
  echo "                         PRINCIPAL={user@domain.tld}"
  echo "      -r | --realm       Authentication realm"
  echo "                         REALM={DOMAIN.TLD}"
  echo "      -z | --zone        Then name of the zone to be updated in AD.
  echo "                         ZONE={zonename}
  echo ""
  echo "Example: $(basename $0) -d domain.tld -i 192.168.0.x -n 192.168.0.x \\"
  echo "             -r DOMAIN.TLD -p user@domain.tld -H HOSTNAME -m"
  echo ""
}

# Process arguments
[ -z "$1" ] && showhelp && exit 1
while [ -n "$1" ]; do
  case $1 in
    -a | --action)
      checkvalues ${1} ${2}
      ACTION=${2}
      shift 2
    ;;
    -c | --krb5cc)
      checkvalues ${1} ${2}
      KRB5CC=${2}
      shift 2
    ;;
    -d | --domain)
      checkvalues ${1} ${2}
      DOMAIN=${2}
      shift 2
    ;;
    -h | --help)
      showhelp
      exit 0
    ;;
    -H | --hostname)
      checkvalues ${1} ${2}
      HNAME=${2%%.*}
      shift 2
    ;;
    -i | --ip)
      checkvalues ${1} ${2}
      IP=${2}
      shift 2
    ;;
    -k | --keytab)
      checkvalues ${1} ${2}
      KEYTAB=${2}
      shift 2
    ;;
    -m | --mitkrb5)
      KRB5MIT=YES
      shift 1
    ;;
    -n | --nameserver)
      checkvalues ${1} ${2}
      NAMESERVER=${2}
      shift 2
    ;;
    -p | --principal)
      checkvalues ${1} ${2}
      PRINCIPAL=${2}
      shift 2
    ;;
    -r | --realm)
      checkvalues ${1} ${2}
      REALM=${2}
      shift 2
    ;;
    -z | --zone)
      checkvalues ${1} ${2}
      ZONE=${2}
      shift 2
    ;;
    *)
      log_error -s "Error!!! Unknown command line opion!"
      log_error -s "Try" `basename $0` "--help."
      exit 1
    ;;
  esac
done

# Sanity checking
[ -z "$ACTION" ] && log_error -s "Error: action not set." && exit 2
case "$ACTION" in
  add | Add | ADD)                      ACTION=ADD ;;
  del | delete | Delete | DEL | DELETE) ACTION=DEL ;;
  *)                                    log_error -s "Error: invalid action \"$ACTION\"." && exit 3
  ;;
esac

[ -z "$KRB5CC" ]     && KRB5CC=/run/dhcpd.krb5cc
[ -z "$DOMAIN" ]     && log_error -s "Error: invalid domain." && exit 4
[ -z "$HNAME" ]      && [ "$ACTION" == "ADD" ] && log_error -s "Error: hostname not set." && exit 5
[ -z "$IP" ]         && log_error -s "Error: IP address not set." && exit 6
[ -z "$KEYTAB" ]     && KEYTAB=/etc/dhcp/dhcpd.keytab
[ -z "$NAMESERVER" ] && log_error -s "Error: nameservers not set." && exit 7
[ -z "$PRINCIPAL" ]  && log_error -s "Error: principal not set." && exit 8
[ -z "$REALM" ]      && log_error -s "Error: realm not set." && exit 9
[ -z "$ZONE" ]       && log_error -s "Error: zone not set." && exit 10

# Disassemble IP for reverse lookups
OCT1=$(echo "$IP" | cut -d . -f 1)
OCT2=$(echo "$IP" | cut -d . -f 2)
OCT3=$(echo "$IP" | cut -d . -f 3)
OCT4=$(echo "$IP" | cut -d . -f 4)
RZONE="$OCT3.$OCT2.$OCT1.in-addr.arpa"

kerberos_creds() {
  export KRB5_KTNAME="$KEYTAB"
  export KRB5CCNAME="$KRB5CC"

  if [ "$KRB5MIT" = "YES" ]; then
    KLISTARG="-s"
  else
    KLISTARG="-t"
  fi

  klist $KLISTARG\
    || kinit -k -t "$KEYTAB" -c "$KRB5CC" "$PRINCIPAL"\
    || { log_error "kinit for dynamic DNS failed"; exit 11; }

}

add_host() {
  log_info "Adding A record for host '$HNAME' with IP '$IP' to zone $ZONE on server $NAMESERVER"
  samba-tool dns add "$NAMESERVER" $ZONE "$HNAME" A "$IP" -k yes
}

delete_host(){
  for ip in $IP ; do
    log_info "Removing A record for host '$HNAME' with IP '$ip' from zone $ZONE on server $NAMESERVER"
    samba-tool dns delete "$NAMESERVER" $ZONE "$HNAME" A "$ip" -k yes
  done
}

update_host(){
  log_info "Updating A record for host '$HNAME' with IP $CURIP from zone $ZONE on server $NAMESERVER"
  for ip in $CURIP ; do
    log_info "Removing A record for host '$HNAME' with IP $ip from zone $ZONE on server $NAMESERVER"
    samba-tool dns delete "$NAMESERVER" $ZONE "$HNAME" A $ip -k yes
  done
  add_host
}


add_ptr(){
  log_info "Adding PTR record '$OCT4' with hostname '$HNAME' to zone '$RZONE' on server $NAMESERVER"
  samba-tool dns add "$NAMESERVER" "$RZONE" "$OCT4" PTR "$HNAME.$DOMAIN" -k yes
}

delete_ptr(){
  log_info "Removing PTR record '$OCT4' with hostname '$HNAME' from zone '$RZONE' on server $NAMESERVER"
  samba-tool dns delete "$NAMESERVER" "$RZONE" "$OCT4" PTR "$HNAME.$DOMAIN" -k yes
}

update_ptr(){
  log_info "Updating PTR record '$OCT4' with hostname $CURHNAME from zone '$RZONE' on server $NAMESERVER"
  for hname in $CURHNAME ; do
    log_info "Removing PTR record '$OCT4' with hostname $hname from zone '$RZONE' on server $NAMESERVER"
    samba-tool dns delete "$NAMESERVER" "$RZONE" "$OCT4" PTR "$hname" -k yes
  done
  add_ptr
}

case "$ACTION" in
  ADD)
    kerberos_creds
    host -t A "$HNAME.$DOMAIN" > /dev/null
    if [ "${?}" == 0 ]; then
      CURIP=$(host -t A "$HNAME.$DOMAIN" | cut -d " " -f 4 )
      if [[ ${CURIP} != ${IP} ]]; then
        update_host
      fi
    else
      add_host
    fi
   
    host -t PTR "$IP" > /dev/null
    if [ "${?}" == 0 ]; then
      CURHNAME=$(host -t PTR "$IP" | cut -d " " -f 5 | rev | cut -c 2- | rev)
      if [[ ${CURHNAME} != ${HNAME}.${DOMAIN} ]]; then 
        update_ptr
      fi
    else
      add_ptr
    fi
    ;;
  DEL)
    kerberos_creds
    host -t A "$HNAME.$DOMAIN" > /dev/null
    if [ "${?}" == 0 ]; then
      delete_host
    fi
    host -t PTR "$IP" > /dev/null
    if [ "${?}" == 0 ]; then
      delete_ptr
    fi
    ;;
  *)
    echo "Error: Invalid action '$ACTION'!" && exit 12
    ;;
esac

log_info "$(basename $0): finished"
# End samba-dnsupdate.sh
