---

secrets::privatevpn::wg::config: "%{alias('secrets::privatevpn::wg::wg1::config')}"

profile::platform::baseline::debian::netplan::ethernets:
  eth0:
    dhcp4: no
    addresses:
      - "%{lookup('defaults::subnet')}.23%{lookup('defaults::bits')}"
    routes:
      - to: default
        via: "%{lookup('defaults::gateway')}"
    nameservers:
      search: "%{alias('defaults::dns::search')}"
      addresses: "%{alias('defaults::dns::nameservers')}"
