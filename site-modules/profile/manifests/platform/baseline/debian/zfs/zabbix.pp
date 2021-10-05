# @summary add zabbix support for zfs
#
class profile::platform::baseline::debian::zfs::zabbix {

# If Zabbix is defined, setup up monitoring
  if defined(Class[profile::app::zabbix::agent]) {
    include sudo
    sudo::conf { 'zabbix-zpool':
      content => 'zabbix  ALL=(root)      NOPASSWD:       /sbin/zpool'
    }
    sudo::conf { 'zabbix-zfs':
      content => 'zabbix  ALL=(root)      NOPASSWD:       /sbin/zfs'
    }

    zabbix::userparameters { 'zfs-auto':
      source => 'puppet:///modules/profile/zfs/zfs-auto.conf'
    }
    zabbix::userparameters { 'zfs-health':
      content => "UserParameter=zpool.health[*],sudo zpool list -H -o health \${1}\n"
    }
  }

  # This gets created on the server
  $template = 'Template App ZFS by Zabbix agent active'

  zabbix::template { $template:
    templ_source => "puppet:///modules/profile/zabbix/server/templates/${template}.xml",
  }

}
