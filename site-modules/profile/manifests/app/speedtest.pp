# @summary gather speedtest data into abbix
#
class profile::app::speedtest {

  package { 'speedtest-cli': }

  $datafile = '/opt/puppetlabs/puppet/cache/speedtest.json'
  $speedtest = '/usr/bin/speedtest-cli'

  cron::job {'speedtest':
    environment => [ 'PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"'],
    command     => "test -x ${speedtest} && ${speedtest} --json > ${datafile}",
    minute      => '53',
    hour        => '*/12',
  }

  include sudo
  sudo::conf { 'speedtest':
    content => 'zabbix  ALL=(root)      NOPASSWD:       /bin/cat'
  }

  zabbix::userparameters { 'speedtest':
    content => "UserParameter=speedtest.data,sudo cat ${datafile}\n"
  }
}
