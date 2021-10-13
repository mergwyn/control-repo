# @summary autosnapshot
#
class profile::platform::baseline::debian::zfs::autosnapshot {

  file {'/etc/cron.hourly/zfs-auto-snapshot':
    ensure  => present,
    mode    => '0775',
    content => @("EOT"/),
               #!/bin/sh
               which zfs-auto-snapshot > /dev/null || exit 0
               zfs-auto-snapshot --quiet --syslog --label=02 --keep=24 // &&
               zsysctl boot update-menu 2>&1 | sed '/GRUB menu/d'
               | EOT
  }
  file {'/etc/cron.daily/zfs-auto-snapshot':
    ensure  => present,
    mode    => '0775',
    content => @("EOT"/),
               #!/bin/sh
               which zfs-auto-snapshot > /dev/null || exit 0
               zfs-auto-snapshot --quiet --syslog --label=03 --keep=14 // &&
               zsysctl boot update-menu 2>&1 | sed '/GRUB menu/d'
               | EOT
  }
  file {'/etc/cron.weekly/zfs-auto-snapshot':
    ensure  => present,
    mode    => '0775',
    content => @("EOT"/),
               #!/bin/sh
               which zfs-auto-snapshot > /dev/null || exit 0
               zfs-auto-snapshot --quiet --syslog --label=04 --keep=4 // &&
               zsysctl boot update-menu 2>&1 | sed '/GRUB menu/d'
               | EOT
  }
  file {'/etc/cron.monthly/zfs-auto-snapshot':
    ensure  => present,
    mode    => '0775',
    content => @("EOT"/),
               #!/bin/sh
               which zfs-auto-snapshot > /dev/null || exit 0
               zfs-auto-snapshot --quiet --syslog --label=05 --keep=6 // &&
               zsysctl boot update-menu 2>&1 | sed '/GRUB menu/d'
               | EOT
  }

  cron::job { 'zfs-auto-snapshot':
    user        => root,
    minute      => '*/15',
    environment => [ 'PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/sbin:/usr/local/bin"' ],
    command     => @("EOT"/),
                   which zfs-auto-snapshot > /dev/null || exit 0 ; \
                   zfs-auto-snapshot --quiet --syslog --label=01 --keep=4  // && \
                   zsysctl boot update-menu 2>&1 | sed '/GRUB menu/d'
                   | EOT
  }

}
