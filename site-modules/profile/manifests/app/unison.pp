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

      $version = '2.53.3'
      $os = downcase($facts['os']['name'])
      $hardware = $facts['os']['hardware']

      $archive_name = "unison-${version}-${os}-${hardware}.tar.gz"

      $url = "https://github.com/bcpierce00/unison/releases/download/v${version}/${archive_name}"
      $archive_path = "${facts['puppet_vardir']}/${archive_name}"
      $install_path = '/opt'
      $extract_dir  = "${install_path}/unison-${version}"
      $creates      = "${extract_dir}/bin/unison"
      $link         = '/usr/local/bin/unison'
      $keep         = 2

      file { $extract_dir: ensure => directory, }

      archive { $archive_path:
        source       => $url,
        extract      => true,
        extract_path => $extract_dir,
        cleanup      => true,
        creates      => $creates,
      }
      file { $link:
        ensure    => 'link',
        target    => $creates,
        subscribe => Archive[$archive_path],
      }
      exec {'unison-tidy':
        cwd         => $install_path,
        path        => '/usr/sbin:/usr/bin:/sbin:/bin:',
        command     => "ls -dtr ${link}-* | head -n -${keep} | xargs rm -rf",
        #onlyif      => "test $(ls -d ${link}-* | wc -l) -gt ${keep}",
        refreshonly => true,
        subscribe   => Archive[$archive_path],
      }

      # TODO add configuration
    }
    default: {
      fail("OS Family: ${facts['os']['family']} not supported by ${::class}")
    }
  }
}
