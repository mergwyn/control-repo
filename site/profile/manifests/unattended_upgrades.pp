# 
# TODO: parameters and settings

class profile::unattended_upgrades {
  include apt
  class {'::unattended_upgrades':
    origins => [
      '${distro_id}:${distro_codename}',                #lint:ignore:single_quote_string_with_variables
      '${distro_id}:${distro_codename}-security',       #lint:ignore:single_quote_string_with_variables
      'Jamie Cameron:stable',
      'Zabbix:${distro_codename}',                      #lint:ignore:single_quote_string_with_variables
      'puppet:${distro_codename}',                      #lint:ignore:single_quote_string_with_variables
    ],
    email   => hiera('defaults::adminemail'), },
  }
  file { '/etc/apt/apt.conf.d/50unattended-upgrades.ucf-dist': ensure  => absent, }
}
# vim: sw=2:ai:nu expandtab
