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
    notify   => Exec['install_requirements'],
    require  => Package['git'],
  }
  file { "${target}/Makefile":
    ensure  => present,
    content => '
PYTHON="--python /usr/bin/python"
install: venv/bin/activate
venv/bin/activate: requirements.txt
	/opt/code/mailman-archive-scraper test -d venv || virtualenv $(PYTHON) venv
	. venv/bin/activate; pip install -Ur requirements.txt
	chmod a+x MailmanArchiveScraper.py
	touch venv/bin/activate
',
  }

  exec { 'install_requirements':
    path        => ['/bin', '/usr/bin', '/sbin', '/usr/sbin', '/usr/local/bin'],
    cwd         => $target,
    command     => 'make install',
    require     => File["${target}/Makefile"],
    refreshonly => true,
  }

# set up cron
  file { '/etc/cron.hourly/mailman-rss':
    ensure  => absent,
    mode    => '0555',
    content => "#!/bin/sh\nexec ${target}/venv/bin/python ${target}/MailmanArchiveScraper.py ${target}/zfs*.cfg\n",
  }

  file { "${target}/zfs-discuss.cfg":
    source => 'puppet:///modules/profile/zfs/zfs-discuss.cfg',
  }
  file { "${htmldir}/rss/zfs-discuss": ensure => directory, }
}
# vim: sw=2:ai:nu expandtab
