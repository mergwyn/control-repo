# @summary Network driver e1000e tuning and configruation
#
# Primary focus is to ensure the network device does not hang
#
class profile::platform::baseline::debian::network::e1000e {

  notice('Applying e1000e network tuning profile')

  # Kernel module tuning
  kmod::option { 'zfs_arc_max':
    module => 'e1000e',
    option => 'InterruptThrottleRate',
    value  => 1,
    notify => Exec['update-initramfs-e1000e'],
  }

  exec { 'update-initramfs-e1000e':
    command     => '/usr/sbin/update-initramfs -u -k all',
    refreshonly => true,
  }

  # Ensure module loads early in initramfs
  file_line { 'e1000e-initramfs':
    path  => '/etc/initramfs-tools/modules',
    line  => 'e1000e',
    match => '^e1000e$',
    notify => Exec['update-initramfs-e1000e'],
  }

  # Runtime tuning script (driver-discovery at runtime)
  file { '/usr/local/sbin/e1000e-tune.sh':
    ensure => file,
    mode   => '0755',
    content => @(EOF)
      #!/bin/bash
      set -e

      for iface in /sys/class/net/*; do
        iface_name=$(basename "$iface")
        driver_path="$iface/device/driver"

        if [ -e "$driver_path" ]; then
          driver=$(basename "$(readlink -f "$driver_path" 2>/dev/null)" 2>/dev/null || true)

          if [ "$driver" = "e1000e" ]; then
            /sbin/ethtool -K "$iface_name" tso off gso off gro off || true
            /sbin/ethtool --set-eee "$iface_name" eee off || true
          fi
        fi
      done
    | EOF
  }

  # systemd service
  systemd::unit_file { 'e1000e-tune.service':
    enable  => false,
    active  => false,
    # lint:ignore:140chars
    content => @("EOT"),
      [Unit]
      Description=e1000e NIC tuning
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=oneshot
      ExecStart=/usr/local/sbin/e1000e-tune.sh
      RemainAfterExit=yes

      [Install]
      WantedBy=multi-user.target
      | EOT
    # lint:endignore
  }

}
