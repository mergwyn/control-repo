#
#
class profile::platform::baseline::windows::base {
#  reboot { 'before':
#    when  => pending,
#  }
#  reboot { 'after':
#    when  => refreshed,
#  }
}
