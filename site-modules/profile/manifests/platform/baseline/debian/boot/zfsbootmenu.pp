# @summary Manage ZFSBootMenu installation and lifecycle
#
# @description
# Installs and maintains ZFSBootMenu from upstream Git using a pinned version.
#
# This class owns the full ZFSBootMenu boot chain on nodes where it applies:
#
# * The ZFSBootMenu-specific dracut setup it needs to build
#   (contained as the private `boot::zfsbootmenu::dracut_setup` class -
#   see that class for why this isn't a top-level, unconditional class)
# * ZFSBootMenu source checkout, build/install, configuration
# * Manual rebuild notification
# * Optional kernel post-install regeneration hook
# * The refind_linux.conf boot stanza that tells rEFInd how to boot via
#   ZFSBootMenu - rEFInd's own config/binary are managed separately by
#   profile::platform::baseline::debian::boot::refind, which boot.pp
#   orders before this class
# * Optional SSH access into the ZFSBootMenu environment itself, via the
#   contained `boot::zfsbootmenu::remote_access` class - opt-in per node,
#   see that class for configuration
#
# Nodes are initially provisioned with ZFSBootMenu already installed via
# https://github.com/Sithuk/ubuntu-server-zfsbootmenu, which is what makes
# has_zfsbootmenu true from the start - this class's job from a Puppet
# run's perspective is to bring src_dir under git management and take over
# from there, cleaning up the non-git directory that script leaves behind
# if needed (see the zfsbootmenu_src_cleanup exec).
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
# @param zbm_timeout
#   Seconds the "Boot default" rEFInd entry waits (via zbm.timeout) before
#   auto-booting the default boot environment. This is also the effective
#   window to SSH in via boot::zfsbootmenu::remote_access before the
#   initramfs (and dropbear with it) is gone - 5s default is fine for
#   normal unattended reboots but is too tight to reliably catch remotely.
#   Raise this on nodes where remote_access is enabled, or connect via the
#   separate "Boot to menu" entry (zbm.show), which waits indefinitely.
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
  Integer $zbm_timeout = 30,
) {
  if $facts['has_zfsbootmenu'] {
    $effective_cmdline = $kernel_cmdline_extra ? {
      undef   => $kernel_cmdline,
      default => "${kernel_cmdline} ${kernel_cmdline_extra}",
    }

    # ZBM-specific dracut packages + config, owned and contained here -
    # see boot::zfsbootmenu::dracut_setup for why.
    contain profile::platform::baseline::debian::boot::zfsbootmenu::dracut_setup

    # Install zbm from the github repo
    package { 'make': ensure => installed, }
    file { '/usr/local/src': ensure => directory, }

    # Node provisioning (github.com/Sithuk/ubuntu-server-zfsbootmenu) sets
    # up ZFSBootMenu directly, without leaving a git working copy at
    # src_dir. On a freshly-provisioned node that leaves a non-git
    # directory sitting where vcsrepo wants to clone, which it refuses to
    # touch. Clear it out first - but only when it genuinely isn't a git
    # repo yet, so this is a no-op on every run once our own clone exists.
    exec { 'zfsbootmenu_src_cleanup':
      command => "/bin/rm -rf ${src_dir}",
      onlyif  => "/usr/bin/test -e ${src_dir} -a ! -d ${src_dir}/.git",
      require => File['/usr/local/src'],
      before  => Vcsrepo[$src_dir],
    }

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
        Class['profile::platform::baseline::debian::boot::zfsbootmenu::dracut_setup'],
      ],
    }

    # Create the zbm config and hooks
    file { [
      '/etc/zfsbootmenu',
      '/etc/zfsbootmenu/generate-zbm.post.d',
      '/etc/zfsbootmenu/dracut.conf.d',
    ]:
      ensure => directory,
    }

    # Opt-in per node via Hiera (see the class itself) - SSH access into
    # the ZFSBootMenu environment, replacing reliance on the blikvm for
    # remote recovery.
    contain profile::platform::baseline::debian::boot::zfsbootmenu::remote_access

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
      content => "\"Boot default\"  \"zfsbootmenu:POOL=rpool zbm.import_policy=hostid zbm.set_hostid zbm.timeout=${zbm_timeout} ro quiet loglevel=0\"\n\"Boot to menu\"  \"zfsbootmenu:POOL=rpool zbm.import_policy=hostid zbm.set_hostid zbm.show ro quiet loglevel=0\"\n",
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
