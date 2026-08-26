# @summary Enable SSH access into the ZFSBootMenu (dracut) pre-boot environment
#
# @description
# Adds a dropbear SSH server to the ZFSBootMenu initramfs image via the
# dracut-crypt-ssh module (https://github.com/dracut-crypt-ssh/dracut-crypt-ssh),
# giving remote access to the ZFSBootMenu menu before the root filesystem is
# mounted - the same use case a KVM-over-IP device covers, without needing one.
#
# dracut-crypt-ssh isn't packaged for Debian/Ubuntu, so it's built from
# upstream Git the same way ZFSBootMenu itself is (see
# boot::zfsbootmenu). Only the module/60crypt-ssh directory is installed -
# the optional `helper` scripts (console snooping / password piping) aren't
# needed for ZFSBootMenu and add extra build dependencies on some systems,
# per upstream's own suggested fallback:
# https://docs.zfsbootmenu.org/en/v3.1.x/general/remote-access.html
#
# Dropbear is configured with dedicated, pre-generated PEM-format host keys
# rather than the node's regular SSH host keys - those can't reliably be
# converted to dropbear's format, and the ZFSBootMenu image is typically on
# a filesystem with no access controls once someone can read the ESP.
# Authorized keys are a symlink to whatever `authorized_keys_path` points
# at (defaults to root's normal authorized_keys), per upstream's
# single-user-machine recommendation.
#
# Networking uses a static IP, embedded into the image itself via
# /etc/cmdline.d (processed by dracut internally at boot) rather than the
# real kernel command line - so it can't collide with kernel_cmdline in
# boot::zfsbootmenu, and doesn't depend on rEFInd passing anything through.
#
# Contained by boot::zfsbootmenu, so it only ever applies on nodes where
# has_zfsbootmenu is true - but does nothing on any of those nodes unless
# `enable` is also set true, so this is opt-in per node via Hiera.
#
# Any resource here that changes what ends up in the image notifies the
# existing NEEDS_REBUILD marker, the same way ZFSBootMenu's own version
# bumps do - run generate-zbm to pick the changes up.
#
# @param enable
#   Whether to build dropbear/crypt-ssh into this node's ZFSBootMenu image.
#   Requires ip, netmask, gateway and interface to also be set.
#
# @param version
#   dracut-crypt-ssh Git tag to build. Renovate tracks this value.
#
# @param repo
#   dracut-crypt-ssh Git repository URL.
#
# @param src_dir
#   Local checkout location for dracut-crypt-ssh.
#
# @param dropbear_port
#   TCP port dropbear listens on inside the initramfs. Deliberately not 22
#   - an SSH client that already trusts this host's real host keys on port
#   22 will refuse to connect when it finds dropbear's different keys there.
#
# @param authorized_keys_path
#   Path to an existing authorized_keys file to symlink into dropbear's ACL.
#   Defaults to root's normal authorized_keys file.
#
# @param ip
#   Static IP address for the ZFSBootMenu environment's network interface.
#   Defaults to the node's existing `node::ip` Hiera value.
#
# @param netmask
#   Netmask for the static IP configuration. Defaults to the common
#   `defaults::netmask` Hiera value.
#
# @param gateway
#   Gateway for the static IP configuration. Defaults to the common
#   `defaults::gateway` Hiera value.
#
# @param interface
#   Physical network interface name to bring up in the initramfs (e.g.
#   'eno1') - deliberately the physical interface rather than any bridge,
#   since bridges aren't up this early in boot. Defaults to the node's
#   existing `node::interface` Hiera value.
#
class profile::platform::baseline::debian::boot::zfsbootmenu::remote_access (
  Boolean $enable                     = false,
  String $version                     = 'v1.0.3', # renovate: datasource=github-tags depName=dracut-crypt-ssh/dracut-crypt-ssh
  String $repo                        = 'https://github.com/dracut-crypt-ssh/dracut-crypt-ssh.git',
  String $src_dir                     = '/usr/local/src/dracut-crypt-ssh',
  Integer $dropbear_port              = 222,
  String $authorized_keys_path        = '/root/.ssh/authorized_keys',
  Optional[String] $ip                = lookup('node::ip', Optional[String], 'first', undef),
  Optional[String] $netmask           = lookup('defaults::netmask', Optional[String], 'first', undef),
  Optional[String] $gateway           = lookup('defaults::gateway', Optional[String], 'first', undef),
  Optional[String] $interface         = lookup('node::interface', Optional[String], 'first', undef),
) {
  if $enable {
    unless $ip and $netmask and $gateway and $interface {
      fail('profile::platform::baseline::debian::boot::zfsbootmenu::remote_access: ip, netmask, gateway and interface are all required when enable is true')
    }

    package { ['dropbear', 'dracut-network']:
      ensure => installed,
    }

    vcsrepo { $src_dir:
      ensure   => present,
      provider => git,
      source   => $repo,
      revision => $version,
      require  => Package['git'],
    }

    # Only the module itself - skip the optional helper scripts, see the
    # class description for why.
    file { '/usr/lib/dracut/modules.d/60crypt-ssh':
      ensure  => directory,
      recurse => true,
      purge   => true,
      source  => "file://${src_dir}/module/60crypt-ssh",
      ignore  => ['helper', 'Makefile'],
      require => Vcsrepo[$src_dir],
      notify  => Exec['zfsbootmenu_needs_rebuild'],
    }

    file { '/etc/dropbear':
      ensure => directory,
    }

    # RSA and ECDSA only - not all dropbear builds support ED25519, and
    # dracut-crypt-ssh only expects these two.
    ['rsa', 'ecdsa'].each |$keytype| {
      exec { "dropbear_host_key_${keytype}":
        command => "/usr/bin/ssh-keygen -q -N '' -m PEM -t ${keytype} -f /etc/dropbear/ssh_host_${keytype}_key",
        creates => "/etc/dropbear/ssh_host_${keytype}_key",
        require => File['/etc/dropbear'],
        notify  => Exec['zfsbootmenu_needs_rebuild'],
      }
    }

    file { '/etc/dropbear/root_key':
      ensure  => link,
      target  => $authorized_keys_path,
      require => File['/etc/dropbear'],
      notify  => Exec['zfsbootmenu_needs_rebuild'],
    }

    file { '/etc/cmdline.d':
      ensure => directory,
    }

    file { '/etc/cmdline.d/dracut-network.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "ip=${ip}::${gateway}:${netmask}::${interface}:none rd.neednet=1\n",
      require => File['/etc/cmdline.d'],
      notify  => Exec['zfsbootmenu_needs_rebuild'],
    }

    file { '/etc/zfsbootmenu/dracut.conf.d/dropbear.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => @("EOF"/L),
        # Enable dropbear ssh server and pull in the static network config
        add_dracutmodules+=" crypt-ssh "
        install_optional_items+=" /etc/cmdline.d/dracut-network.conf "
        dropbear_rsa_key=/etc/dropbear/ssh_host_rsa_key
        dropbear_ecdsa_key=/etc/dropbear/ssh_host_ecdsa_key
        dropbear_acl=/etc/dropbear/root_key
        dropbear_port=${dropbear_port}
        | EOF
      require => [
        File['/etc/zfsbootmenu/dracut.conf.d'],
        File['/usr/lib/dracut/modules.d/60crypt-ssh'],
        Exec['dropbear_host_key_rsa'],
        Exec['dropbear_host_key_ecdsa'],
        File['/etc/dropbear/root_key'],
        File['/etc/cmdline.d/dracut-network.conf'],
      ],
      notify  => Exec['zfsbootmenu_needs_rebuild'],
    }
  }
}
