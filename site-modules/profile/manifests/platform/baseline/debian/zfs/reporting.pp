# @summary monthly reporting
#
class profile::platform::baseline::debian::zfs::reporting {

  # zfs monthly reporting
  file {'/usr/local/bin/zfs_report.sh':
    ensure => present,
    source => 'puppet:///modules/profile/zfs/zfs_report.sh',
    mode   => '0775',
  }

  file {'/etc/cron.monthly/zfs-montly-report':
    ensure  => present,
    mode    => '0775',
    content => @("EOT"/),
               #!/bin/sh
               /usr/local/bin/zfs_report.sh
               | EOT
  }

}
