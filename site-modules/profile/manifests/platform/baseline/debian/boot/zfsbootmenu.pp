# @summary Manage ZFSBootMenu installation and lifecycle
#
# @description
# Installs and maintains ZFSBootMenu from upstream Git using a pinned version.
#
# This class manages:
#
# * ZFSBootMenu source checkout
# * ZFSBootMenu build/install
# * ZFSBootMenu configuration
# * Manual rebuild notification
# * Optional kernel post-install regeneration hook
#
# By default Puppet does not generate EFI boot images. Instead it creates
# a NEEDS_REBUILD marker requiring an operator to run generate-zbm.
#
# When auto_regenerate is enabled, a kernel postinst hook will regenerate
# ZFSBootMenu automatically after kernel installation.
#
# @example
#   include profile::platform::baseline::debian::boot::zfsbootmenu
#
# @example
#   class { 'profile::platform::baseline::debian::boot::zfsbootmenu':
#     auto_regenerate => true,
#   }
#
# @param version
#   ZFSBootMenu Git tag or revision to deploy.
#   Renovate tracks this value.
#
# @param repo
#   ZFSBootMenu Git repository URL.
#
# @param src_dir
#   Local checkout location.
#
# @param efi_dir
#   EFI image output directory.
#
# @param manage_images
#   Whether generate-zbm manages EFI images.
#
# @param versions
#   Number of ZFSBootMenu versions retained.
#
# @param kernel_cmdline
#   Base kernel command line.
#
# @param kernel_cmdline_extra
#   Additional node-specific kernel arguments.
#
# @param auto_regenerate
#   Install kernel postinst hook to automatically run generate-zbm.
#
class profile::platform::baseline::debian::boot::zfsbootmenu (
  String $version = 'v3.1.0', # renovate: datasource=github-tags depName=zbm-dev/zfsbootmenu
  String $repo = 'https://github.com/zbm-dev/zfsbootmenu.git',
  String $src_dir = '/usr/local/src/zfsbootmenu',
  String $efi_dir = '/boot/efi/EFI/ubuntu',
  Boolean $manage_images = true,
  Integer $versions = 1,
  String $kernel_cmdline = 'rd.vconsole.keymap=gb ro quiet loglevel=0',
  Optional[String] $kernel_cmdline_extra = undef,
  Boolean $auto_regenerate = true,
) {
  if $facts['has_zfsbootmenu'] {
    $effective_cmdline = $kernel_cmdline_extra ? {
      undef   => $kernel_cmdline,
      default => "${kernel_cmdline} ${kernel_cmdline_extra}",
    }

    # Install zbm from the github repo
    package { 'make': ensure => installed, }
    file { '/usr/local/src': ensure => directory, }

    vcsrepo { $src_dir:
      ensure   => present,
      provider => git,
      source   => $repo,
      revision => $version,
      require  => Package['git'],
    }

    exec { 'zfsbootmenu_build':
      command     => '/usr/bin/make core dracut',
      cwd         => $src_dir,
      refreshonly => true,
      subscribe   => Vcsrepo[$src_dir],
      require     => [
        Package['make'],
        File['/etc/dracut.conf.d/99-zfsbootmenu.conf'],
      ],
    }

    # Create the zbm config and hooks
    file { [
      '/etc/zfsbootmenu',
      '/etc/zfsbootmenu/generate-zbm.post.d',
    ]:
      ensure => directory,
    }

    file { '/etc/zfsbootmenu/config.yaml':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => epp('profile/boot/zbm_config.epp', {
        'efi_dir'        => $efi_dir,
        'manage_images'  => $manage_images,
        'versions'       => $versions,
        'kernel_cmdline' => $effective_cmdline,
      }),
      require => Exec['zfsbootmenu_build'],
    }

    # Add notifcation if a manual rebuild of zbm is required
    file { '/etc/zfsbootmenu/NEEDS_REBUILD':
      ensure    => file,
      owner     => 'root',
      group     => 'root',
      mode      => '0644',
      content   => "ZFSBootMenu configuration changed or updated to ${version}. Run 'generate-zbm' manually.\n",
      replace   => true,
      require   => File['/etc/zfsbootmenu/config.yaml'],
      subscribe => Exec['zfsbootmenu_build'],
    }

    # Clear down the notificaton via a zbm post install hook
    file { '/etc/zfsbootmenu/generate-zbm.post.d/99-clear-marker':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => @("EOF"/L),
        #!/bin/sh
        rm -f /etc/zfsbootmenu/NEEDS_REBUILD
        exit 0
        | EOF
      require => File['/etc/zfsbootmenu/generate-zbm.post.d'],
    }

    if $auto_regenerate {
      file { '/etc/kernel/postinst.d/60-zfsbootmenu':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        content => epp('profile/boot/zbm_regen_hook.epp'),
        require => Exec['zfsbootmenu_build'],
      }
    } else {
      file { '/etc/kernel/postinst.d/60-zfsbootmenu':
        ensure => absent,
      }
    }

    file { '/boot/efi/EFI/ubuntu/refind_linux.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => @(EOF),
        "Boot default"  "zfsbootmenu:POOL=rpool zbm.import_policy=hostid zbm.set_hostid zbm.timeout=5 ro quiet loglevel=0"
        "Boot to menu"  "zfsbootmenu:POOL=rpool zbm.import_policy=hostid zbm.set_hostid zbm.show ro quiet loglevel=0"
        | EOF
    }

    # Tidy updateinitramfs hooks
    file {
      [
        '/etc/kernel/postinst.d/initramfs-tools',
        '/etc/kernel/postinst.d/zz-update-grub',
      ]:
        ensure => absent,
    }

    # Add motd message if rebuild is required
    file { '/etc/update-motd.d/99-zfsbootmenu':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => @("EOF"/L$),
        #!/bin/sh

        MARKER="/etc/zfsbootmenu/NEEDS_REBUILD"

        if [ -f "\$MARKER" ]; then
          echo ""
          echo "ZFSBootMenu needs regeneration"
          echo "Run: generate-zbm"
          echo ""
        fi
        | EOF
    }

    # Add validation script for hostid
    file { '/usr/local/sbin/check-zfs-hostid':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => @("EOF"/L$),
        #!/bin/sh
        set -e

        if [ ! -f /sys/module/spl/parameters/spl_hostid ]; then
          exit 0
        fi

        spl=$(cat /sys/module/spl/parameters/spl_hostid)
        host=$(hostid | tr '[:lower:]' '[:upper:]')

        if [ "\$spl" != "\$host" ]; then
          echo "WARNING: ZFS hostid mismatch"
          echo "SPL:    \$spl"
          echo "hostid: \$host"
          exit 1
        fi
        | EOF
    }
  }
}
