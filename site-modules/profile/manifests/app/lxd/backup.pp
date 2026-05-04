#
#
class profile::app::lxd::backup (
  Boolean $enable = false,
) {
  $codedir = '/opt/lxdbackup'

  if $enable {
    include profile::app::git
    include profile::app::scripts
    include cron

    $repo_ensure = 'latest'
    $cron_ensure = 'present'
  } else {
    $repo_ensure = 'absent'
    $cron_ensure = 'absent'
  }

  vcsrepo { $codedir:
    ensure   => $repo_ensure,
    provider => git,
    source   => 'https://github.com/mergwyn/lxdbackup.git',
    revision => 'master',
  }

  cron::job { 'lxdbackup':
    ensure      => $cron_ensure,
    environment => ['PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"'],
    command     => "${codedir}/lxdbackup",
    user        => 'gary',
    minute      => fqdn_rand(59, 'lxdbackup'),
    hour        => fqdn_rand(5, 'lxdbackup'),
  }
}
