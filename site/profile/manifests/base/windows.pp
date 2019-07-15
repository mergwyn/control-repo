#

class profile::base::windows {
  reboot { 'before':
    when  => pending,
  }
  reboot { 'after':
    when  => refreshed,
  }
#  dism {'Microsoft-Windows-Subsystem-Linux':
#    ensure    => present,
#    norestart => true,
#  }
  scheduled_task { 'GPO Backup':
    command     => "powershell.exe",
    arguments   => "-ExecutionPolicy RemoteSigned \\\\${lookup('defaults::backup_server')}\\backup\\GPO\\GPOBackup.ps1",
    working_dir => "\\\\${lookup('defaults::backup_server')}\\backup\\${trusted['hostname']}\\GPO\\",
    enabled     => true,
    user        => 'THECLARKHOME\\gary',
    password    => hiera('secrets::gary'),
    trigger     => [
      {
        schedule   => 'daily',
        start_time => '02:30'
      }
    ],
  }
}

# vim: sw=2:ai:nu expandtab
