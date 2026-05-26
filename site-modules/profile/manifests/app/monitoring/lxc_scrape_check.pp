class profile::app::monitoring::lxc_scrape_check (
  String        $prometheus_url = "http://prometheus.${trusted['domain']}",
  String        $scrape_job     = 'node-exporter-lxc',
  Array[String] $exclude        = [],
) {
  file { '/etc/cron.daily/prometheus-lxc-check':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => epp('profile/prometheus-lxc-check.sh.epp', {
      prometheus_url => $prometheus_url,
      scrape_job     => $scrape_job,
      exclude        => $exclude,
    }),
  }
}
