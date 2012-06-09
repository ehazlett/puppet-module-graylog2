class graylog2::config inherits graylog2::params {
  Exec { 
    path      => "${::path}", 
    logoutput => on_failure,
  }
  if ($graylog2::update_local_syslog) {
    if ! defined(Package["rsyslog"]) { package { "rsyslog": ensure => installed, } }
    if ! defined(Service["rsyslog"]) { service { "rsyslog": ensure => running, } }
    file { "graylog2::config::default_syslog_conf":
      ensure  => present,
      path    => "/etc/rsyslog.d/50-default.conf",
      content => template("graylog2/rsyslog-50-default.conf.erb"),
      notify  => Service["rsyslog"],
    }
  }
}
