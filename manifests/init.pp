# Class: graylog2
#
# This module manages graylog2
#
# Parameters:
#   n/a
# Actions:
#   Installs and configures Graylog2 logger
# Requires:
#   n/a
#
# Sample usage:
#
#  include graylog2
#
class graylog2 (
    $server_name=$graylog2::params::server_name, 
    $external_hostname=$graylog2::params::external_hostname,
    $update_local_syslog=$graylog2::params::update_local_syslog
  ) inherits graylog2::params {
  class { 'graylog2::config': }
  class { 'graylog2::package':
    require => Class['graylog2::config'],
  }
}
