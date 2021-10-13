# summary Unison 
#
class profile::app::unison {

  case $facts['os']['family'] {
    'Darwin': {
      file {
        default:
          ensure => file,
        ;
        '/usr/local/share/com.theclarkhome.prefsync.plist':
          source => 'puppet:///modules/profile/mac/com.theclarkhome.prefsync.plist',
        ;
        '/usr/local/share/com.theclarkhome.logoutwatcher.plist':
          source => 'puppet:///modules/profile/mac/com.theclarkhome.logoutwatcher.plist',
        ;
        '/usr/local/share/Home.prf':
          source => 'puppet:///modules/profile/mac/Home.prf',
        ;
        '/usr/local/share/default.prf':
          source => 'puppet:///modules/profile/mac/default.prf',
        ;
        '/usr/local/share/Preferences.prf':
          source => 'puppet:///modules/profile/mac/Preferences.prf',
        ;
        '/usr/local/share/common.prf':
          source => 'puppet:///modules/profile/mac/common.prf',
        ;
        '/usr/local/bin/UnisonHomeSync.sh':
          source => 'puppet:///modules/profile/mac/UnisonHomeSync.sh',
          mode   => '0775',
        ;
        '/usr/local/bin/SetupHomeSync.sh':
          source => 'puppet:///modules/profile/mac/SetupHomeSync.sh',
          mode   => '0775',
        ;
        '/usr/local/bin/logoutwatcher.sh':
          source => 'puppet:///modules/profile/mac/logoutwatcher.sh',
          mode   => '0775',
        ;
        '/etc/newsyslog.d/unison.conf':
          source => 'puppet:///modules/profile/mac/unison.conf',
        ;
        '/Library/Logs/unison.log':
          mode => '0666',
        ;
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
        source       => $url,
        extract      => true,
        extract_path => $install_path,
        cleanup      => false,
        creates      => $creates,
      }
      # TODO add configuration
    }
    default: {
      fail("OS Family: ${facts['os']['family']} not supported by ${::class}")
    }
  }
}
