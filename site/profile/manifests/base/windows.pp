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
#  scheduled_task { 'GPO Backup':
#    command   => "$::system32\\WindowsPowerShell\\v1.0\\powershell.exe",
#    arguments => '-ExecutionPolicy RemoteSigned \\foxtrot\backup\GPO\GPOBackup.ps1',
#    working_dir => "\\foxtrot\backup\${trusted['hostname']}\GPO\",
#    enabled   => 'true',
#    trigger   => [
#      {
#        schedule   => 'daily',
#        start_time => '02:30'
#        user       => 'theclarkhome\\gary',
#      }
#    ],
#  }
}

# vim: sw=2:ai:nu expandtab
