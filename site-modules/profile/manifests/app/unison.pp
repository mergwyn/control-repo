# summary Unison 

class profile::app::unison {

  case $facts['os']['family'] {
    'Darwin': {
      file { '/usr/local/share/com.theclarkhome.prefsync.plist':
        source => 'puppet:///modules/profile/mac/com.theclarkhome.prefsync.plist',
      }
      file { '/usr/local/share/com.theclarkhome.logoutwatcher.plist':
        source => 'puppet:///modules/profile/mac/com.theclarkhome.logoutwatcher.plist',
      }
      file { '/usr/local/share/Home.prf':
        source => 'puppet:///modules/profile/mac/Home.prf',
      }
      file { '/usr/local/share/default.prf':
        source => 'puppet:///modules/profile/mac/default.prf',
      }
      file { '/usr/local/share/Preferences.prf':
        source => 'puppet:///modules/profile/mac/Preferences.prf',
      }
      file { '/usr/local/share/common.prf':
        source => 'puppet:///modules/profile/mac/common.prf',
      }
      file { '/usr/local/bin/UnisonHomeSync.sh':
        source => 'puppet:///modules/profile/mac/UnisonHomeSync.sh',
        mode   => '0775',
      }
      file { '/usr/local/bin/SetupHomeSync.sh':
        source => 'puppet:///modules/profile/mac/SetupHomeSync.sh',
        mode   => '0775',
      }
      file { '/usr/local/bin/logoutwatcher.sh':
        source => 'puppet:///modules/profile/mac/logoutwatcher.sh',
        mode   => '0775',
      }
      file { '/etc/newsyslog.d/unison.conf':
        source => 'puppet:///modules/profile/mac/unison.conf',
      }
      file { '/Library/Logs/unison.log':
        mode => '0666',
      }
    }
    'Debian': {
      package { 'unison': ensure => absent, }

      case $facts['os']['architecture'] {
        'amd64': { $archive_name = 'unison-v2.51.3+ocaml-4.10.0+x86_64.linux.static.tar.gz' }
        default: { }
      }
      $url = "https://github.com/bcpierce00/unison/releases/download/v2.51.3/${archive_name}"
      $archive_path = "${facts['puppet_vardir']}/${archive_name}"
      $install_path = '/usr'
      $creates      = "${install_path}/bin/unison"

      archive { $archive_path:
        source       => "file://${archive_path}",
        extract      => true,
        extract_path => $install_path,
        cleanup      => false,
      }
      # TODO add configuration
    }
    default: {
      fail("OS Family: ${facts['os']['family']} not supported by ${::class}")
    }
  }
}
