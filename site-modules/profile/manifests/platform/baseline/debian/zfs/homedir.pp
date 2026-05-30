# profile/manifests/platform/baseline/debian/zfs/homedir.pp
# Creates ZFS datasets for home directories on first login via PAM

class profile::platform::baseline::debian::zfs::homedir (
  String $pool = 'rpool',
) {
  file { '/usr/local/sbin/mkhomedir-zfs':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    content => @("EOF"/L$),
      #!/bin/bash
      # Don't create ZFS datasets for root or system accounts
      if [ "\$PAM_USER" = "root" ]; then
          exit 0
      fi

      HOMEDIR=\$(getent passwd "\$PAM_USER" | cut -d: -f6)

      # Only act on home dirs under /home
      if [[ "\$HOMEDIR" != /home/* ]]; then
          exit 0
      fi

      if [ ! -d "\$HOMEDIR" ]; then
          USERNAME=\$PAM_USER
          zfs create -o mountpoint="\$HOMEDIR" ${pool}/home/\$USERNAME
          chown \$USERNAME:\$USERNAME "\$HOMEDIR"
          chmod 750 "\$HOMEDIR"
      fi
      | EOF
  }

  pam { 'zfs mkhomedir':
    ensure    => present,
    service   => 'common-session',
    type      => 'session',
    control   => 'optional',
    module    => 'pam_exec.so',
    arguments => '/usr/local/sbin/mkhomedir-zfs',
    require   => File['/usr/local/sbin/mkhomedir-zfs'],
  }
}
