# profile::app::age
#
class profile::app::age (
  String $version,
) {
  $bin_dir = '/usr/local/bin'
  $bin     = "${bin_dir}/age"

  exec { 'install-age':
    command => @(END),
      curl -Lo /tmp/age.tar.gz https://github.com/FiloSottile/age/releases/download/v${version}/age-v${version}-linux-amd64.tar.gz
      tar -xzf /tmp/age.tar.gz -C ${bin_dir} age
      chmod +x ${bin_dir}/age
      rm -f /tmp/age.tar.gz
    END
    creates => $bin,
    path    => ['/usr/bin', '/bin'],
    require => Package['curl'],
  }
}
