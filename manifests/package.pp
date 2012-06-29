class graylog2::package {
  require "graylog2::config"

  Exec {
    path      => "${::path}",
    logoutput => on_failure,
  }
  if ! defined(Package["autoconf"]) { package { "autoconf": ensure => installed, } }
  if ! defined(Package["irb"]) { package { "irb": ensure => installed, } }
  if ! defined(Package["libopenssl-ruby"]) { package { "libopenssl-ruby": ensure => installed, } }
  if ! defined(Package["libreadline-ruby"]) { package { "libreadline-ruby": ensure => installed, } }
  if ! defined(Package["openjdk-6-jre"]) { package { "openjdk-6-jre": ensure => installed, } }
  if ! defined(Package["rake"]) { package { "rake": ensure => installed, } }
  if ! defined(Package["rdoc"]) { package { "rdoc": ensure => installed, } }
  if ! defined(Package["ri"]) { package { "ri": ensure => installed, } }
  if ! defined(Package["ruby"]) { package { "ruby": ensure => installed, } }
  if ! defined(Package["ruby-dev"]) { package { "ruby-dev": ensure => installed, } }
  if ! defined(Package["supervisor"]) { package { "supervisor": ensure => installed, } }

  exec { "graylog2::package::get_updated_rubygems":
    command => "wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz && tar zxf rubygems* && cd rubygems* && ruby setup.rb && cd ../ && rm -rf rubygems*",
    unless  => "gem -v | grep 1.3.7",
    notify  => Exec["graylog2::package::update_alternate_rubygems"],
  }

  exec { "graylog2::package::update_alternate_rubygems":
    command     => "update-alternatives --install /usr/bin/gem gem /usr/bin/gem1.8 1",
    require     => Exec["graylog2::package::get_updated_rubygems"],
    refreshonly => true,
  }
  exec { "graylog2::package::update_supervisor":
    command     => "supervisorctl update",
    require     => [ Package["openjdk-6-jre"], Package["ruby"], File["graylog2::package::mongodb_data"],
      File["graylog2::package::elasticsearch_data"], File["graylog2::package::graylog_general_config"], File["graylog2::package::graylog_email_config"],
      File["graylog2::package::graylog_supervisor_config"], File["graylog2::package::graylog2_web_config"], File["graylog2::package::graylog2_server_config"] ],
    refreshonly => true,
  }
  # elasticsearch
  exec { "graylog2::package::wget_elasticsearch":
    cwd       => "/tmp",
    command   => "wget ${graylog2::params::elasticsearch_url} -O elasticsearch.tar.gz",
    creates   => "${graylog2::params::elasticsearch_dir}/bin/elasticsearch",
    notify    => Exec["graylog2::package::extract_elasticsearch"],
  }
  exec { "graylog2::package::extract_elasticsearch":
    cwd         => "/tmp",
    command     => "tar zxf elasticsearch.tar.gz ; mv elasticsearch-* /opt/ ; mv /opt/elasticsearch* ${graylog2::params::elasticsearch_dir} ; rm -rf elasticsearch*",
    refreshonly => true,
    require     => Exec["graylog2::package::wget_elasticsearch"],
  }
  file { "graylog2::package::elasticsearch_data":
    ensure  => directory,
    path    => "${graylog2::params::elasticsearch_dir}/data",
    require => Exec["graylog2::package::extract_elasticsearch"],
  }

  file { "graylog2::package::elasticsearch_logs":
    ensure  => directory,
    path    => "${graylog2::params::elasticsearch_dir}/logs",
    require => Exec["graylog2::package::extract_elasticsearch"],
  }
  file { "graylog2::package:elasticsearch_conf":
    path      => "/etc/supervisor/conf.d/elasticsearch.conf",
    content => template("graylog2/elasticsearch.conf.erb"),
    notify    => Exec["graylog2::package::update_supervisor"],
    require   => [ File["graylog2::package::elasticsearch_data"], File["graylog2::package::elasticsearch_data"], Exec["graylog2::package::extract_elasticsearch"], Package["supervisor"] ],
  }
  # graylog
  exec { "graylog2::package::wget_graylog":
    cwd       => "/tmp",
    command   => "wget ${graylog2::params::graylog_web_url} -O graylog.tar.gz",
    creates   => "${graylog2::params::graylog_dir}/Rakefile",
    notify    => Exec["graylog2::package::extract_graylog"],
  }
  exec { "graylog2::package::extract_graylog":
    cwd         => "/tmp",
    command     => "tar zxf graylog.tar.gz ; mv graylog2-web* /opt/ ; mv /opt/graylog2-web* ${graylog2::params::graylog_dir} ; rm -rf graylog*",
    refreshonly => true,
    notify      => Exec["graylog2::package::bundle_install"],
    require     => Exec["graylog2::package::wget_graylog"],
  }
  file { "graylog2::package::graylog_general_config":
    ensure    => present,
    path      => "${graylog2::params::graylog_dir}/config/general.yml",
    content   => template("graylog2/general.yml.erb"),
    owner     => root,
    group     => root,
    require   => Exec["graylog2::package::extract_graylog"],
  }
  file { "graylog2::package::graylog_email_config":
    ensure    => present,
    path      => "${graylog2::params::graylog_dir}/config/email.yml",
    source    => "puppet:///modules/graylog2/email.yml",
    owner     => root,
    group     => root,
    require   => Exec["graylog2::package::extract_graylog"],
  }
  file { "graylog2::package::graylog_mongoid_config":
    ensure    => present,
    path      => "${graylog2::params::graylog_dir}/config/mongoid.yml",
    source    => "puppet:///modules/graylog2/mongoid.yml",
    owner     => root,
    group     => root,
    require   => Exec["graylog2::package::extract_graylog"],
  }
  file { "graylog2::package::graylog_supervisor_config":
    path      => "/etc/supervisor/conf.d/graylog-web.conf",
    content   => template("graylog2/graylog.conf.erb"),
    notify    => Exec["graylog2::package::update_supervisor"],
    require   => [ File["graylog2::package::graylog_mongoid_config"], Package["supervisor"] ],
  }
  exec { "graylog2::package::wget_mongodb":
    cwd       => "/tmp",
    command   => "wget ${graylog2::params::mongodb_url} -O mongodb.tar.gz",
    creates   => "${graylog2::params::mongodb_dir}/bin/mongod",
    notify    => Exec["graylog2::package::extract_mongodb"],
  }
  exec { "graylog2::package::extract_mongodb":
    cwd         => "/tmp",
    command     => "tar zxf mongodb.tar.gz ; mv mongodb-linux* /opt/ ; mv /opt/mongodb-linux* ${graylog2::params::mongodb_dir} ; rm -rf mongodb*",
    refreshonly => true,
    require     => Exec["graylog2::package::wget_mongodb"],
  }
  file { "graylog2::package::mongodb_data":
    ensure    => directory,
    path      => "${graylog2::params::mongodb_data_dir}",
    owner     => root,
    group     => root,
    require   => Exec["graylog2::package::extract_mongodb"],
  }
  file { "graylog2::package::mongodb_supervisor_conf":
    path      => "/etc/supervisor/conf.d/mongodb.conf",
    content   => template("graylog2/mongodb.conf.erb"),
    notify    => Exec["graylog2::package::update_supervisor"],
    require   => [ File["graylog2::package::mongodb_data"], Exec["graylog2::package::extract_mongodb"], Package["supervisor"] ],
  }
  package { "bundler":
    provider    => gem,
    require     => [ Exec["graylog2::package::get_updated_rubygems"], Exec["graylog2::package::update_alternate_rubygems"] ],
  }
  exec { "graylog2::package::bundle_install":
    cwd         => "${graylog2::params::graylog_dir}",
    command     => "bundle install",
    user        => root,
    require     => [ Package["bundler"], Exec["graylog2::package::extract_graylog"], Package["ruby-dev"] ],
    refreshonly => true,
  }
  exec { "graylog2::package::wget_graylog_server":
    cwd       => "/tmp",
    command   => "wget ${graylog2::params::graylog_server_url} -O graylog-server.tar.gz",
    creates   => "${graylog2::params::graylog_server_dir}/graylog2-server.jar",
    notify    => Exec["graylog2::package::extract_graylog_server"],
  }
  exec { "graylog2::package::extract_graylog_server":
    cwd         => "/tmp",
    command     => "tar zxf graylog-server.tar.gz ; mv graylog2-server* /opt/ ; mv /opt/graylog2-server* ${graylog2::params::graylog_server_dir} ; rm -rf graylog*",
    refreshonly => true,
    require     => Exec["graylog2::package::wget_graylog_server"],
  }
  file { "graylog2::package::graylog2_web_config":
    ensure    => present,
    path      => "/etc/graylog2.conf",
    content   => template("graylog2/graylog2_web.conf.erb"),
    owner     => root,
    group     => root,
  }
  file { "graylog2::package::graylog2_server_config":
    ensure    => present,
    path      => "/etc/supervisor/conf.d/graylog2-server.conf",
    content   => template("graylog2/graylog2_server.conf.erb"),
    notify    => Exec["graylog2::package::update_supervisor"],
    require   => [ Exec["graylog2::package::extract_graylog_server"], Package["supervisor"] ],
  }
  # end graylog
}
