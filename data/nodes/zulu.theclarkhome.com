---

secrets::privatevpn::wg::config: "%{alias('secrets::privatevpn::wg::wg2::config')}"

profile::platform::baseline::debian::netplan::ethernets:
  eth0:
    dhcp4: no
    addresses:
      - "%{lookup('defaults::subnet')}.24/%{lookup('defaults::bits')}"
    routes:
      - to: default
        via: "%{lookup('defaults::gateway')}"
    nameservers:
      search: "%{alias('defaults::dns::search')}"
      addresses: "%{alias('defaults::dns::nameservers')}"
