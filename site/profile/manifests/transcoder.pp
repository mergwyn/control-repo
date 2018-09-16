#

class profile::transcoder {
  include profile::git

  $codedir='/opt/code/scripts'

  # lxd snap related commands
  vcsrepo { $codedir:
      ensure   => present,
      provider => git,
      require  => Package['git'],
      source   => 'https://github.com/mergwyn/scripts.git',
      revision => 'latest',
  }

  include cron
  cron::job { 'media':
    environment => [ 'PATH="/usr/sbin:/usr/bin:/sbin:/bin"' ],
    command     => "test -x ${codedir}/bin/process_media_job && ${codedir}/bin/process_media_job",
    user        => 'media',
    minute      => 5,
    hour        => '0-18',
  }
}
# vim: sw=2:ai:nu expandtab
