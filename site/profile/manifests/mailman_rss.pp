#
# TODO: sudo configuration

class profile::mailman_rss (
    $codedir = '/opt/code',
    $bindir  = '/usr/local/bin',
    $htmldi  = '/usr/share/nginx/html',
  ) {

  include profile::git

  file { "${htmldir}/rss": ensure => directory, }

  $target="${codedir}/mailman-archive-scraper"

  # install commands
  vcsrepo { $target:
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/philgyford/mailman-archive-scraper',
    revision => 'master',
    require  => Package['git'],
    notify   => Exec['install_requirements', 'chmod']
  }
  exec { 'install_requirements':
    path        => ['/bin', '/usr/bin', '/sbin', '/usr/sbin', '/usr/local/bin'],
    cwd         => "${target}",
    command     => 'pip install -r requirements.txt',
    refreshonly => true
  }
  exec { 'chmod':
    path        => ['/bin', '/usr/bin', '/sbin', '/usr/sbin', '/usr/local/bin'],
    command     => "chmod a+x ${target}/MailmanArchiveScraper.py",
    refreshonly => true
  }

  # set up cron
  file { '/etc/cron.hourly/mailman-rss':
    ensure  => absent,
    mode    => '0555',
    content => "#!/bin/sh\nexec /usr/bin/python ${target}/MailmanArchiveScraper.py ${target}/zfs*.cfg\n",
  }

  file { "${target}/zfs-discuss.cfg":
    source => 'puppet:///modules/profile/zfs/zfs-discuss.cfg',
  }
  file { "${htmldir}/rss/zfs-discuss": ensure => directory, }
}
# vim: sw=2:ai:nu expandtab
