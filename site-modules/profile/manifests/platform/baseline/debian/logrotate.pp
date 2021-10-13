#
# Remove compression on logrotate files
#
class profile::platform::baseline::debian::logrotate {

  $confdir = '/etc/logrotate.d'
  exec { 'remove compression':
    path    => $facts['path'],
    onlyif  => "grep -ql '[[:space:]]compress' ${confdir}/*",
    command => "sed -i -e '/[[:space:]]compress/d'  \$(grep -l '[[:space:]]compress' ${confdir}/*)",
  }
}
