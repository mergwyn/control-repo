# @summary Keepalived global notification settings
#
#
class profile::app::keepalived::notify (
  Stdlib::Email           $notification_email = lookup('defaults::adminemail'),
  Stdlib::Email           $notification_email_from = "keepalived@${trusted['domain']}",
) {

  include keepalived

# Global defs
  class { 'keepalived::global_defs':
    notification_email      => $notification_email,
    notification_email_from => $notification_email_from,
    smtp_server             => 'localhost',
    smtp_connect_timeout    => '60',
    enable_script_security  => true,
    script_user             => 'root',
  }

}
