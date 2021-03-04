#

class profile::infrastructure::router::privatvpn {

  include profile::infrastructure::router::openvpn

# TODO Install confia:  wget 'http://privatevpn.com/client/PrivateVPN-TUN.zip' -O $openvpn/PrivateVPN-TUN.zipg
# TODO get credentials
# TODO add port 1195
  firewalld_port {'Open port 1195 in the public Zone':
    ensure   => 'present',
    zone     => 'public',
    port     => 1195,
    protocol => 'udp',
  }
# TODO setup config file
#cat <<! >$openvpn/privat.conf
#remote uk-lon.pvdata.host 1195 udp
#config  "${openvpn}/PrivateVPN-TUN/UDP/PrivateVPN-UK-London 1-TUN-1194.ovpn"
#auth-user-pass '/etc/openvpn/privat.auth'
#comp-lzo no
#script-security 2
#up /etc/openvpn/update-resolv-conf # use systemd version
#down /etc/openvpn/update-resolv-conf # use systemd version
#down-pre
#!

# TODO setup local DNS for local domain

}
