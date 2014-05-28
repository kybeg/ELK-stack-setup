#!/bin/bash

# versions
LOGSTASH_VER="1.4.1"
ES_VER="1.4.0"
KIBANA_VER="3.1.0"

ES_CLUSTER="ES-CLUSTER"
INSTALL_DIR="/elk"

mkdir -p $INSTALL_DIR

cd $INSTALL_DIR

apt-get update
apt-get install -y openjdk-7-jre redis-server apache2

# logstash
curl -O https://download.elasticsearch.org/logstash/logstash/logstash-$LOGSTASH_VER.tar.gz
tar xzf logstash-$LOGSTASH_VER.tar.gz

# Elasticsearch
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-$ES_VER.deb
dpkg -i elasticsearch-$ES_VER.deb

# configure Elasticsearch
nano /etc/elasticsearch/elasticsearch.yml
service elasticsearch restart

# Kibana
wget https://download.elasticsearch.org/kibana/kibana/kibana-$KIBANA_VER.tar.gz
tar xzf kibana-$KIBANA_VER.tar.gz
cp -R kibana-$KIBANA_VER/* /var/www
nano /var/www/config.js


# configure redis
# /etc/redis/redis.conf
# ...
nano /etc/redis/redis.conf
service redis-server restart


# fix /etc/nginx/sites-enabled/default


# configure logstash server: 
# nano /etc/logstash/server.conf
mkdir /etc/logstash
echo 'input {
  redis {
    host => "10.0.6.15"
    type => "redis"
    data_type => "list"
    key => "logstash"
  }
  tcp {
    port => 8888
    type => listentcp
    tags => [ 'lmetrics' ]
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
}' > /etc/logstash/server.conf
