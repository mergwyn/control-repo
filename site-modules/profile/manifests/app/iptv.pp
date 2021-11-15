#
#
class profile::app::iptv {
  include cron
  include profile::app::scripts

  $codedir='/opt/scripts'

  $packages = [ 'socat' ]
  package { $packages: ensure => present }

#  class{'::tvheadend':
#    release        => 'stable',
#    admin_password => lookup('secrets::tvheadend'),
#  }

#    environment => [
#     'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/puppetlabs/bin:/opt/puppetlabs/puppet/bin"'
#  }

  cron::job { 'xmltv': ensure => absent }

# systemd timer to download channels
  $adminemail = lookup('defaults::adminemail')
  $_timer = @(EOT)
    [Unit]
    Description=Run get channels on boot and 6 hourly

    [Timer]
    OnBootSec=10min
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
  include profile::app::nginx::xmltv
}
