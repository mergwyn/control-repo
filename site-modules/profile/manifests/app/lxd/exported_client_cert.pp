#
define profile::app::lxd::exported_client_cert (
  String $fqdn,
  Optional[Sensitive[String]] $cert = undef,
) {
  # Absolutely no validation here
}
