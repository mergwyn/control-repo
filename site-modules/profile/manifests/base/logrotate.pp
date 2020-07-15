#
# Remove compression on logrotate files

class profile::base::logrotate {

  $confdir = '/etc/logrotate.d'
  exec { 'remove compression':
    path    => 'default path',
    onlyif  => "grep -ql '[[:space:]]compress' ${confdir}/*",
    command => "sed -i -e '/[[:space:]]compress/d'  \$(grep -l '[[:space:]]compress' ${confdir}/*)",
  }
}
# vim: sw=2:ai:nu expandtab