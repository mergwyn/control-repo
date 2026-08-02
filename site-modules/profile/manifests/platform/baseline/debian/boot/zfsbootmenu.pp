# @summary Manage ZFSBootMenu installation (manual image generation model)
#
# @description
# Installs and maintains ZFSBootMenu from upstream Git using a pinned version.
# This class is designed for a safe, manual boot artifact workflow:
#
# * Puppet manages source, install, and configuration
# * Puppet does NOT run `generate-zbm`
# * Operator manually regenerates EFI images when ready
#
# This avoids accidental boot breakage during automated runs.
#
# When the version changes:
# * The repository is updated
# * `make core dracut` is executed
# * A marker file is written to indicate manual action is required
#
# Kernel command line handling:
# * `kernel_cmdline` defines the global/default baseline
# * `kernel_cmdline_extra` allows per-node extension
# * Both are concatenated safely
#
# @example Basic usage
#   include profile::platform::baseline::debian::boot::zfsbootmenu
#
# @example Override version and enable dual images
#   class { 'profile::platform::baseline::debian::boot::zfsbootmenu':
#     version  => 'v3.0.2',
#     versions => 2,
#   }
#
# @example Add node-specific kernel flags
#   class { 'profile::platform::baseline::debian::boot::zfsbootmenu':
#     kernel_cmdline_extra => 'intel_iommu=on iommu=pt',
#   }
#
# @param version
#   ZFSBootMenu Git tag or revision to deploy (Renovate-managed)
#
# @param repo
#   Git repository URL for ZFSBootMenu
#
# @param src_dir
#   Local path where the repository will be cloned
#
# @param efi_dir
#   Target EFI directory where ZBM images will be written
#
# @param manage_images
#   Whether ZBM writes EFI images when `generate-zbm` is run
#
# @param versions
#   Number of historical images to retain for rollback safety
#
# @param kernel_cmdline
#   Base kernel command line
#
# @param kernel_cmdline_extra
#   Optional per-node kernel command line additions
#
class profile::platform::baseline::debian::boot::zfsbootmenu (
  String  $version               = 'v3.1.0', # renovate: datasource=github-tags depName=zbm-dev/zfsbootmenu
  String  $repo                  = 'https://github.com/zbm-dev/zfsbootmenu.git',
  String  $src_dir               = '/usr/local/src/zfsbootmenu',
  String  $efi_dir               = '/boot/efi/EFI/ubuntu',
  Boolean $manage_images         = true,
  Integer $versions              = 1,
  String  $kernel_cmdline        = 'rd.vconsole.keymap=gb ro quiet loglevel=0',
  Optional[String] $kernel_cmdline_extra = undef,
) {
  if $facts['has_zfsbootmenu'] {
    $effective_cmdline = $kernel_cmdline_extra ? {
      undef   => $kernel_cmdline,
      default => "${kernel_cmdline} ${kernel_cmdline_extra}",
    }

    package { ['make', 'dracut']:
      ensure => installed,
    }

    file { '/usr/local/src':
      ensure => directory,
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
      require     => Package['make'],
    }

    file { ['/etc/zfsbootmenu', '/etc/zfsbootmenu/generate-zbm.post.d']:
      ensure => directory,
    }

    file { '/etc/zfsbootmenu/config.yaml':
      ensure  => file,
      content => epp('profile/boot/zbm_config.epp', {
        'efi_dir'        => $efi_dir,
        'manage_images'  => $manage_images,
        'versions'       => $versions,
        'kernel_cmdline' => $effective_cmdline,
      }),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }

    file { '/etc/zfsbootmenu/NEEDS_REBUILD':
      ensure    => file,
      content   => "ZFSBootMenu updated to ${version}. Run 'generate-zbm' manually.\n",
      owner     => 'root',
      group     => 'root',
      mode      => '0644',
      replace   => true,
      subscribe => [
        Exec['zfsbootmenu_build'],
        File['/etc/zfsbootmenu/config.yaml'],
      ],
    }

    notify { "ZFSBootMenu ${version} installed — run generate-zbm manually":
      subscribe => Exec['zfsbootmenu_build'],
    }

    file { '/etc/update-motd.d/99-zfsbootmenu':
      ensure  => file,
      mode    => '0755',
      owner   => 'root',
      group   => 'root',
      content => @("EOF"/L$),
        #!/bin/sh
        MARKER="/etc/zfsbootmenu/NEEDS_REBUILD"
        if [ -f "\$MARKER" ]; then
          echo ""
          echo "⚠️  ZFSBootMenu needs regeneration"
          echo "   Run: generate-zbm"
          echo ""
        fi
        EOF
    }

    file { '/etc/zfsbootmenu/generate-zbm.post.d/99-clear-marker':
      ensure  => file,
      mode    => '0755',
      content => @("EOF"/),
        #!/bin/sh
        rm -f /etc/zfsbootmenu/NEEDS_REBUILD
        EOF
      require => File['/etc/zfsbootmenu/generate-zbm.post.d'],
    }
  }
}
