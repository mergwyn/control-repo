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
      '${distro_id}:${distro_codename}',           #lint:ignore:single_quote_string_with_variables
      '${distro_id}:${distro_codename}-security',  #lint:ignore:single_quote_string_with_variables
      'Jamie Cameron:stable',
      'Zabbix:${distro_codename}',                 #lint:ignore:single_quote_string_with_variables
      'puppet:${distro_codename}',                 #lint:ignore:single_quote_string_with_variables
    ],
    mail    => {
      'to'            => lookup('defaults::adminemail'),
      'only_on_error' => false,
    }
  }

  file { '/etc/apt/apt.conf.d/50unattended-upgrades.ucf-dist': ensure  => absent, }
}
