#
#
class profile::app::dns {
  package { 'bind9':
    ensure => installed,
  }

  service { 'bind9':
    ensure  => running,
    enable  => true,
    require => Package['bind9'],
  }

  # ---- named.conf.local ----
  file { '/etc/bind/named.conf.local':
    owner   => 'root',
    group   => 'bind',
    mode    => '0644',
    notify  => Service['bind9'],
    content => @("EOF"),
//
// Samba AD DLZ
//
dlz "AD DNS Zone" {
    database "dlopen /usr/lib/x86_64-linux-gnu/samba/bind9/dlz_bind9.so";
};
EOF
  }

  # ---- named.conf.options ----
  file { '/etc/bind/named.conf.options':
    owner   => 'root',
    group   => 'bind',
    mode    => '0644',
    notify  => Service['bind9'],
    content => @("EOF"),
options {
    directory "/var/cache/bind";

    tkey-gssapi-keytab "/etc/kea/dhcp.keytab";

    listen-on { any; };
    listen-on-v6 { any; };

    allow-query { any; };
    recursion yes;

    dnssec-validation no;
};
EOF
  }

  # ---- Samba config enforcement ----
  augeas { 'samba-dns-backend':
    context => '/files/etc/samba/smb.conf/global',
    changes => [
      'set dns_backend bind9',
      'set server_services "+dns"',
    ],
    notify  => Service['samba-ad-dc'],
  }

  service { 'samba-ad-dc':
    ensure => running,
    enable => true,
  }
}
