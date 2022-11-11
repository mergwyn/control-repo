#
#
class profile::app::iptv {
  include cron
  include profile::app::scripts

  $codedir='/opt/scripts'

  $packages = [ 'socat' ]
  package { $packages: ensure => present }

# systemd timer to download channels
  $adminemail = lookup('defaults::adminemail')
  $_timer = @(EOT)
    [Unit]
    Description=Run get channels on boot and periodically

    [Timer]
    OnBootSec=20min
    OnUnitActiveSec=6h

    [Install]
    WantedBy=timers.target
    | EOT

  $_service = @("EOT")
    [Unit]
    Description=runs channel download
    Wants=getchannels.timer

    [Service]
    Type=oneshot
    ExecStart=/bin/bash -c '${codedir}/iptv/get-channels 2>&1 | /usr/bin/mailx -v -E -s "%N output root@%H" ${adminemail}'

    [Install]
    WantedBy=multi-user.target
    | EOT

  systemd::timer{'getchannels.timer':
    timer_content   => $_timer,
    service_content => $_service,
    enable          => true,
  }

  #TODO xteve?

  if defined('profile::app::zabbix::agent') {
    profile::app::zabbix::template_host { 'Template App xTeve by Zabbix agent active': }
  }

}
