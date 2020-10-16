# @summary development server
class role::development {
  include profile::platform::baseline
  include profile::domain::sso
  include profile::git
# TODO: git, others etc?
}
