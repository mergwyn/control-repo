# summary Install and configure unison
#
class profile::app::unison (
  String $version = '2.54.0', # renovate: datasource=github-releases depName=bcpierce00/unison
) {
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
      $os = downcase($facts['os']['name'])
      $hardware = $facts['os']['hardware']

      profile::app::binary_install { 'unison':
        version     => $version,
        binary      => ['unison', 'unison-fsmonitor'],
        #url         => "https://github.com/bcpierce00/unison/releases/download/v${version}/unison-${version}-${os}-${hardware}.tar.gz",
        #TODO: The above URL is the correct one, but the unison-fsmonitor binary is not included in that tarball.  The following URL is a workaround that includes both binaries, but it is not the official release.  We should try to get the official release to include both binaries.
        url         => "https://github.com/bcpierce00/unison/releases/download/v${version}/unison-${version}-ubuntu-22.04-${hardware}.tar.gz",
        tarball     => true,
        tar_extract => ['bin/unison', 'bin/unison-fsmonitor'],
        version_cmd => 'unison -version',
      }
      # TODO add configuration
    }
    default: {
      fail("OS Family: ${facts['os']['family']} not supported by ${facts['class']}")
    }
  }
}
