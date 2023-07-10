# @summary unattended upgrade settings for debian
#
#
class profile::platform::baseline::debian::unattended_upgrades {
  include apt
  class {'::unattended_upgrades':
    update  => 1,
    auto    => {
      remove => true,
    },
    origins => [
      'origin=${distro_id},suite=${distro_codename}',           #lint:ignore:single_quote_string_with_variables
      'origin=${distro_id},suite=${distro_codename}-security',  #lint:ignore:single_quote_string_with_variables
      "origin='Jamie Cameron',suite=stable",
      'origin=Zabbix,suite=${distro_codename}',                 #lint:ignore:single_quote_string_with_variables
      'origin=puppet,suite=${distro_codename}',                 #lint:ignore:single_quote_string_with_variables
    ],
    mail    => {
      'to'            => lookup('defaults::adminemail'),
      'only_on_error' => false,
    }
  }

  file { '/etc/apt/apt.conf.d/50unattended-upgrades.ucf-dist': ensure  => absent, }
}
