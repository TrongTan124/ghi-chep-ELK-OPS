#!/bin/bash

# import config va function can thiet
source config.cfg
source functions.sh

# Install Logstash Forwarder Package. create the Logstash Forwarder source list
echocolor "Cai dat Logstash Forwarder Package"
sleep 3

echo 'deb http://packages.elasticsearch.org/logstashforwarder/debian stable main' | sudo tee /etc/apt/sources.list.d/logstashforwarder.list
wget -O - http://packages.elasticsearch.org/GPG-KEY-elasticsearch | sudo apt-key add -

CHECK_MACHINE=`uname -m`
if [ "$CHECK_MACHINE" = "x86_64" ]; then
	apt-get update -y && apt-get install logstash-forwarder -y
else 
	wget https://assets.digitalocean.com/articles/logstash/logstash-forwarder_0.3.1_i386.deb
	dpkg -i logstash-forwarder_0.3.1_i386.deb
fi

cd /etc/init.d/
wget https://raw.githubusercontent.com/elasticsearch/logstash-forwarder/a73e1cb7e43c6de97050912b5bb35910c0f8d0da/logstash-forwarder.init -O logstash-forwarder
chmod +x logstash-forwarder
update-rc.d logstash-forwarder defaults

mkdir -p /etc/pki/tls/certs
cp /tmp/logstash-forwarder.crt /etc/pki/tls/certs/

# Tao file JSON format
cat << EOF > /etc/logstash-forwarder
###
{
  "network": {
    "servers": [ "$IP_ELK_SERVER:5000" ],
    "timeout": 15,
    "ssl ca": "/etc/pki/tls/certs/logstash-forwarder.crt"
  },
  "files": [
    {
      "paths": [
        "/var/log/syslog",
        "/var/log/auth.log"
       ],
      "fields": { "type": "syslog" }
    }
   ]
}
EOF

# restart logstash forwarder
echocolor "Khoi dong lai logstash forwarder"
sleep 3
service logstash-forwarder restart

echocolor "Hoan thanh cai dat!"