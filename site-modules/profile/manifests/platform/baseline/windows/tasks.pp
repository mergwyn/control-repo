# Dynamically create Puppet task resources using the Puppet built-in
# 'create_resources' function.
#
#
class profile::platform::baseline::windows::tasks (
  Hash           $objects  = {},
  Optional[Hash] $defaults = {},
) {

  case $::kernel {
    'windows': {
      scheduled_task { 'GPO Backup':
        ensure      => present,
        enabled     => true,
        command     => "${facts['os']['windows']['system32']}\\WindowsPowerShell\\v1.0\\powershell.exe",
        arguments   => "-ExecutionPolicy RemoteSigned \\\\${lookup('defaults::backup_server')}\\backup\\GPO\\GPOBackup.ps1",
        working_dir => "\\\\${lookup('defaults::backup_server')}\\backup\\${trusted['hostname']}\\GPO\\",
        user        => "${lookup('defaults::workgroup')}\\backup",
        password    => lookup('secrets::backup'),
        trigger     => [
          {
            schedule   => 'daily',
            start_time => '02:30'
          }
        ],
      }

      unless empty ($objects) {
        create_resources(scheduled_task, $objects, $defaults)
      }
    }
    default: {
    }
  }

}
