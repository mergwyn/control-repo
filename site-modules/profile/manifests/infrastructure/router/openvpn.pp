#

class profile::infrastructure::router::openvpn {

  $aptpackages = [
    'ufw',
    'openvpn',
    'unzip',
    'ca-certificates',
  ]
  package { $aptpackages: ensure   => present, }
  #
  #TODO configure ufw
  #TODO configure openvpn
# wget https://downloads.nordcdn.com/configs/archives/servers/ovpn.zip
# unzip ovpn.zip
# rm ovpn.zip
# set up configuration file
#  ==> creds <==
#username
#password
#
#==> fastest.server <==
#config /etc/openvpn/ovpn_udp/uk1928.nordvpn.com.udp.ovpn
#
#==> nordvpn.conf <==
#config /etc/openvpn/client/fastest.server
## Use local credentials
#auth-user-pass /etc/openvpn/client/creds
#==> /etc/systemd/system/openvpn-client@.service.d/disable-limitnproc.conf
#[Service]
#LimitNPROC=infinity

}
