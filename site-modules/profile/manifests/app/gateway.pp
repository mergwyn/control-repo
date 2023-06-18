# @summary certificates and reverse proxy
#
class profile::app::gateway {

  if $facts['os']['family'] != 'Debian' {
    fail("${title} is only for Debian")
  }

  #include profile::app::gateway::certs
  include profile::app::nginx::gateway

}
