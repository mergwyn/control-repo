# @summary Set up cron job for trim

class profile::platform::baseline::debian::zfs::trim {


  $script = '/usr/lib/zfs-linux/trim'

  file { $script:
    ensure => present,
    mode   => '0555',
    source => 'puppet:///modules/profile/zfs/trim',
  }

  cron::job { 'zfs-trim':
# trim the fourth Sunday of every month.
    user        => root,
    minute      => '24',
    hour        => '0',
    day         => '22-28',
    environment => [ 'PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/sbin:/usr/local/bin"' ],
    command     => "if [ $(date +\%w) -eq 0 ] && [ -x ${script} ]; then ${script}; fi",
  }
}
