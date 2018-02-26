# 
# TODO: parameters and settings

class profile::unattended_upgrades {
  #$upgrade_blacklist = hiera_array('do_not_upgrade')
  #class {'::unattended_upgrades': }
  class {'::unattended_upgrades':
    #period    => '1',
    #autoremove => true,
    repos     => {
      "${lsbdistcodename}-security" => { origin => "Ubuntu", },
      #"${lsbdistcodename}" => { origin => "Ubuntu", },
      #"${lsbdistcodename}-updates" => { origin => "Ubuntu", },
      #"${lsbdistcodename}-proposed" => { origin => "Ubuntu", },
      #"${lsbdistcodename}-backports" => { origin => "Ubuntu", },
      "Zabbix" => { origin => "Zabbix", },
      stable => { origin => 'Jamie Cameron', },
    },
    #blacklist => $upgrade_blacklist,
    #email     => hiera("adminemail"),
  }
  file { "/etc/apt/apt.conf.d/50unattended-upgrades.ucf-dist": ensure  => absent, }
}
# vim: sw=2:ai:nu expandtab
