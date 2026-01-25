#
#
class profile::app::lxd::backup {
  include profile::app::git
  include profile::app::scripts
  include cron

  $codedir = '/opt/lxdbackup'

  vcsrepo { $codedir:
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/mergwyn/lxdbackup.git',
    revision => 'master',
  }

  cron::job { 'lxdbackup':
    environment => ['PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"'],
    command     => "${codedir}/lxdbackup",
    user        => 'gary',
    minute      => fqdn_rand(59, 'lxdbackup'),
    hour        => fqdn_rand(5, 'lxdbackup'),
  }
}
