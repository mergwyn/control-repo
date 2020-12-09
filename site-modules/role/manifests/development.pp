# @summary development server
class role::development {
  include profile::platform::baseline
  include profile::puppet::dev
  include profile::app::sssd
  include profile::app::git
# TODO: git, others etc?
}
