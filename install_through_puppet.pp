

$LOGSTASH_VER = "1.4.2"
$ES_VER = "1.3.4"
$KIBANA_VER = "3.1.1"

$ES_CLUSTER = "ES-CLUSTER"
$INSTALL_DIR = "/elk"

$DOWNLOAD_DIR = "/tmp"

$LOGSTASH_CONTENT = '
input {
  redis {
    host => "127.0.0.1"
    type => "redis"
    data_type => "list"
    key => "logstash"
  }
  syslog {
    tags => [ "syslogmessage" ]
    type => syslog
  }
  tcp {
    port => 8888
    type => listentcp
    tags => [ "tcpmessage" ]
  }
}

filter {
grok {
    type => listentcp
    match => [ "message" , "put %{DATA:metric} %{NUMBER:value}" ]
}

}

output {
stdout { }
  elasticsearch {
    cluster => "elasticsearch"
  }
}'




file { "elk-dir":
    name => $INSTALL_DIR,
    ensure => "directory",
}

file { "/etc/logstash":
    ensure => "directory",
}

# install java
package { "openjdk-7-jre" :
  ensure => present,
  require => File["elk-dir"],
}

package { "redis-server" :
  ensure => present,
  require => File["elk-dir"],
}

package { "apache2" :
  ensure => present,
  require => File["elk-dir"],
}

# 
# LOGSTASH

exec { "download-logstash" :
    path => "/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/bin",
    command => "curl https://download.elasticsearch.org/logstash/logstash/logstash-$LOGSTASH_VER.tar.gz | tar xz -C $DOWNLOAD_DIR",
    unless => "ls $DOWNLOAD_DIR/logstash-$LOGSTASH_VER",
}

# ELASTICSEARCH

exec { "download-elasticsearch" :
    path => "/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/bin",
    command => "wget -O $DOWNLOAD_DIR/elasticsearch-$ES_VER.deb https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-$ES_VER.deb",
    unless => "ls $DOWNLOAD_DIR/elasticsearch-$ES_VER.deb",
}

exec { "install-elasticsearch" :
    path => "/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/bin",
    command => "dpkg -i $DOWNLOAD_DIR/elasticsearch-$ES_VER.deb",
    unless => "dpkg -l elasticsearch",
    require => Exec['download-elasticsearch'],
}

service { "elasticsearch" :
    ensure => running,
    require => Exec['install-elasticsearch'],
    }

# KIBANA

exec { "download-kibana" :
    path => "/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/bin",
    command => "curl https://download.elasticsearch.org/kibana/kibana/kibana-$KIBANA_VER.tar.gz | tar xz --strip-components 1 -C /var/www",
    unless => "ls /var/www/config.js",
    require => Package['apache2'],
}

# not really needed
# exec { "configure-kibana" :
#    path => "/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/bin",
#     command => "sed -i 's/\s+elasticsearch:.*window\.location\.hostname.*/elasticsearch: http://localhost:9200,/' /var/www/config.js"
# }
# tar xzf kibana-$KIBANA_VER.tar.gz
# cp -R kibana-$KIBANA_VER/* /var/www
# nano /var/www/config.js

service { "redis-server" :
  ensure => running,
  require => Package['redis-server'],
  }


exec { "configure-redis" :
  path => "/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/bin",
  command => "sed -i 's/bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf",
  unless => "grep 'bind 0.0.0.0' /etc/redis/redis.conf",
  notify => Service['redis-server'],
  require => Package['redis-server'],
}
		
exec { "configure-logstash" :
  path => "/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/bin",
  command => "echo '$LOGSTASH_CONTENT' > /etc/logstash/logstash.conf",
  unless => "ls /etc/logstash/logstash.conf",
  require => Exec['download-logstash'],
}

