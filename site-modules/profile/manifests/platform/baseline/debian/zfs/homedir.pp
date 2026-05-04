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
      USERNAME=\$PAM_USER
      if [ ! -d /home/\$USERNAME ]; then
          zfs create -o mountpoint=/home/\$USERNAME ${pool}/home/\$USERNAME
          chown \$USERNAME:\$USERNAME /home/\$USERNAME
          chmod 750 /home/\$USERNAME
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
