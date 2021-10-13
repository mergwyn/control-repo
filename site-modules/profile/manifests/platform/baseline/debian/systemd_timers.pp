# @summary cron style standard timers for systemd
#
#
class profile::platform::baseline::debian::systemd_timers {

  if $facts['os']['family'] != 'Debian' {
    fail("${name} can only be called on Debian")
  }
  systemd::timer{'hourly.timer':
    active        => true,
    enable        => true,
    timer_content => @("EOT"/),
                     [Timer]
                     OnCalendar=hourly
                     RandomizedDelaySec=30m
                     | EOT
  }

  systemd::timer{'daily.timer':
    active        => true,
    enable        => true,
    timer_content => @("EOT"/),
                     [Timer]
                     OnCalendar=daily
                     RandomizedDelaySec=30m
                     | EOT
  }

  systemd::timer{'weekly.timer':
    active        => true,
    enable        => true,
    timer_content => @("EOT"/),
                     [Timer]
                     OnCalendar=weekly
                     RandomizedDelaySec=30m
                     | EOT
  }

  systemd::timer{'monthly.timer':
    active        => true,
    enable        => true,
    timer_content => @("EOT"/),
                     [Timer]
                     OnCalendar=monthly
                     RandomizedDelaySec=30m
                     | EOT
  }
}
