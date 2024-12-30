# @summary monthly reporting
#
class profile::platform::baseline::debian::zfs::reporting {
  # zfs monthly reporting
  file { '/usr/local/bin/zfs_report.sh':
    ensure => file,
    source => 'puppet:///modules/profile/zfs/zfs_report.sh',
    mode   => '0775',
  }

  # lint:ignore:strict_indent
  file { '/etc/cron.monthly/zfs-montly-report':
    ensure  => file,
    mode    => '0775',
    content => @("EOT"/),
               #!/bin/sh
               /usr/local/bin/zfs_report.sh
               | EOT
  }
# lint:endignore
}
