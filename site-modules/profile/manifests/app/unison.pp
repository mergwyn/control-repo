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
        'amd64': { $edition = 'ocaml-4.10.1+x86_64.linux' }
        default: { }
      }

      $archive_name = "/unison.latest.${edition}.tar.gz"
      $archive_path = "${facts['puppet_vardir']}/${archive_name}"
      $install_path = '/usr'
      $creates      = "${install_path}/bin/unison"

      githubreleases_download { $archive_path:
        author            => 'bcpierce00',
        repository        => 'unison',
        asset             => true,
        asset_filepattern => $edition,
      }
      archive { $archive_name:
        source       => "file://${archive_path}",
        extract      => true,
        extract_path => $install_path,
        cleanup      => false,
        subscribe    => Githubreleases_download[$archive_path],
      }
        # TODO add configuration
    }
    default: {
      fail("OS Family: ${facts['os']['family']} not supported by ${::class}")
    }
  }
}
