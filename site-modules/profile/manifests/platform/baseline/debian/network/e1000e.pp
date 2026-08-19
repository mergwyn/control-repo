# @summary Network driver e1000e tuning and configruation
#
# Primary focus is to ensure the network device does not hang
#
class profile::platform::baseline::debian::network::e1000e {
  # Ensure module loads early in initramfs
  $provider = $facts['initramfs_provider']

  $config = $provider ? {
    'dracut' => {
      type    => 'file',
      path    => '/etc/dracut.conf.d/e1000e.conf',
      content => "add_drivers+=\" e1000e \"\n",
    },
    'initramfs-tools' => {
      type => 'file_line',
      path => '/etc/initramfs-tools/modules',
      line => 'e1000e',
      match => '^e1000e$',
    },
    default => undef,
  }

  if $config {
    if $config['type'] == 'file' {
      file { $config['path']:
        ensure  => file,
        content => $config['content'],
        notify  => Exec['rebuild_initramfs'],
      }
    } else {
      file_line { 'e1000e-initramfs':
        path   => $config['path'],
        line   => $config['line'],
        match  => $config['match'],
        notify => Exec['rebuild_initramfs'],
      }
    }
  }

  # Runtime tuning script (driver-discovery at runtime)
  file { '/usr/local/bin/e1000e-tune.sh':
    ensure  => file,
    mode    => '0755',
    content => @(EOF),
      #!/usr/bin/env bash
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
    enable  => true,
    active  => true,
    # lint:ignore:140chars
    content => @("EOT"),
      [Unit]
      Description=e1000e NIC tuning
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=oneshot
      ExecStart=/usr/local/bin/e1000e-tune.sh
      RemainAfterExit=yes

      [Install]
      WantedBy=multi-user.target
      | EOT
    # lint:endignore
  }
}
