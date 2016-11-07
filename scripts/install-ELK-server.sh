#!/bin/bash -ex

# import config va function can thiet
source config.cfg
source functions.sh

# cap nhat he thong
echocolor "Kiem tra va cap nhat he dieu hanh"
sleep 5

apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y

# Cai dat cac goi can thiet
echocolor "Cai dat cac goi can thiet"

echocolor "Installing CRUDINI"
	sleep 3
	apt-get install python-iniparse -y
	mkdir -p /root/crudini
	cd /root/crudini

	CHECK_MACHINE=`uname -m`
	if [ "$CHECK_MACHINE" = "x86_64" ]; then
		wget http://ftp.us.debian.org/debian/pool/main/c/crudini/crudini_0.7-1_amd64.deb
		dpkg -i crudini_0.7-1_amd64.deb
	else 
		wget http://ftp.us.debian.org/debian/pool/main/c/crudini/crudini_0.7-1_i386.deb
		dpkg -i crudini_0.7-1_i386.deb
	fi

echocolor "Cai dat java 8"
	sleep 3
	add-apt-repository -y ppa:webupd8team/java
	apt-get update -y
	# silent option
	echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections #silent option
	echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections
	# install
	apt-get install oracle-java8-installer -y
	bash -c "echo JAVA_HOME=/usr/lib/jvm/java-8-oracle/bin/ >> /etc/environment"

echocolor "Kiem tra lai java sau khi cai dat"
sleep 3

java -version

sleep 3

# Cai dat Elasticsearch
echocolor "Cai dat Elasticsearch"
	sleep 3
	mkdir -p /root/elasticsearch
	cd /root/elasticsearch
	wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
	apt-get update -y && apt-get -y install elasticsearch

# Cau hinh elasticsearch
# elasticsearch.yml — Configures the Elasticsearch server settings. 
# This is where all options, except those for logging, are stored, 
# which is why we are mostly interested in this file


# logging.yml — Provides configuration for logging. 
# In the beginning, you don't have to edit this file. 
# You can leave all default logging options. 
# You can find the resulting logs in /var/log/elasticsearch by default
echocolor "Chinh sua cau hinh Elasticsearch"
	sleep 3
	elasticsearchfile=/etc/elasticsearch/elasticsearch.yml

	test -f $elasticsearchfile.orgi || cp $elasticsearchfile $elasticsearchfile.orgi		# backup lai file config

	sed -i 's/# network.host: 192.168.0.1/network.host: localhost/g' $elasticsearchfile
	sed -i 's/# node.name: node-1/node.name: "My First Node"/g' $elasticsearchfile
	sed -i 's/# cluster.name: my-application/cluster.name: mycluster1/g' $elasticsearchfile


# Restart elasticsearch
echocolor "Khoi dong lai elasticsearch"
	sleep 3
	/etc/init.d/elasticsearch restart

# Add elasticsearch on startup
update-rc.d elasticsearch defaults

echocolor "Cai dat Kibana"
	sleep 5
	mkdir -p /root/kibana
	cd /root/kibana
	echo "deb http://packages.elastic.co/kibana/4.5/debian stable main" | sudo tee -a /etc/apt/sources.list
	apt-get update -y && apt-get -y install kibana

# Cau hinh kibana
echocolor "Chinh sua cau hinh Kibana"
	sleep 3
	kibanafile=/opt/kibana/config/kibana.yml
	test -f $kibanafile.orgi || cp $kibanafile $kibanafile.orgi		# backup lai file config

	sed -i 's/# server.host: "0.0.0.0"/server.host: "localhost"/g' $kibanafile

# Add kibana on startup
update-rc.d kibana defaults

# Khoi dong lai kibana
/etc/init.d/kibana restart

# Cai dat nginx de lam proxy truy cap kibana
echocolor "Cai dat Nginx"
	sleep 3
	apt-get -y install nginx

# Thieu lap ssl truy cap tu nginx toi kibana
# echo "kibanaadmin:`openssl passwd -apr1`" | sudo tee -a /etc/nginx/htpasswd.users
echo "$KIBANA_USER_LOGIN:`openssl passwd -apr1 $KIBANA_PASSWD_LOGIN`" | sudo tee -a /etc/nginx/htpasswd.users

# Cau hinh nginx
echocolor "Chinh sua cau hinh Nginx"
	sleep 3
	nginxfile=/etc/nginx/sites-available/default
	test -f $nginxfile.orgi || cp $nginxfile $nginxfile.orgi 	# backup lai file configuration
	rm -rf $nginxfile
cat << 'EOF' > $nginxfile
##
server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;

        root /usr/share/nginx/html;
        index index.html index.htm;

        # Make site accessible from http://localhost/
        server_name ops.com;

        auth_basic "Restricted Access";
        auth_basic_user_file /etc/nginx/htpasswd.users;


        location / {
                proxy_pass http://localhost:5601;
                proxy_http_version 1.1;
                proxy_set_header Upgrade $http_upgrade;
                proxy_set_header Connection 'upgrade';
                proxy_set_header Host $host;
                proxy_cache_bypass $http_upgrade;
        }
}
EOF

# checl nginx config ok
nginx -t

# restart nginx
/etc/init.d/nginx restart

# neu firewall on thi add them rule
ufw allow 'Nginx Full'
ufw reload

# Cai dat Logstash
echocolor "Cai dat Logstash"
	sleep 3
	mkdir -p /root/Logstash
	cd /root/Logstash

	#  add repository 
	echo "deb http://packages.elastic.co/logstash/2.3/debian stable main" | sudo tee -a /etc/apt/sources.list
	apt-get update -y && apt-get install logstash -y

echocolor "Cau hinh Logstash"
	sleep 3

while [ $FILEBEAT_BOOLEAN ]; do

		# Generate SSL Certificates
		# This script use filebeat to ship logs from client to ELK serrver, we need to create an SSL Certificate and key pair.
		# The certificate is used by Filebeat to verify the identity of ELK Server

		# Create the directories that will store the certificate and private key
		mkdir -p /etc/pki/tls/certs
		mkdir -p /etc/pki/tls/private

		# have two options for generating your SSL certificates
		# Option 1: allow you to use IP addresses ELK Server
		# Option 2: If you have a DNS setup that will allow your client servers to resolve the IP address of the ELK Server

	if [ $FILEBEAT_OPTION = ip_address ]; then

		# Config Option 1: IP Address
		# you will have to add your ELK Server's private IP address to the subjectAltName (SAN) field of the SSL certificate that we are about to generate. 
		# To do so, open the OpenSSL configuration file:
		opensslfile=/etc/ssl/openssl.cnf
		test -f $opensslfile.orgi || cp $opensslfile $opensslfile.orgi

		crudini --set $opensslfile " v3_ca " subjectAltName IP:$IP_ELK_SERVER

		# generate the SSL certificate and private key in the appropriate locations (/etc/pki/tls/...)
		cd /etc/pki/tls
		openssl req -config /etc/ssl/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt
		break

	elif [ $FILEBEAT_OPTION = fqdn_dns ]; then
		# Config Option 2: FQDN (DNS)
		# generate the SSL certificate and private key, in the appropriate locations (/etc/pki/tls/...)
		cd /etc/pki/tls
		openssl req -subj '/CN=ELK_server_fqdn/' -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt
		break

	else
		echocolor "Neu ban chon cai dat Filebeat, ban phai chon ip_address hoac fqdn_dns. Ban hay dien lai optione se cai dat."
		read input_option
		FILEBEAT_OPTION=$input_option
		FILEBEAT_BOOLEAN=true
	fi

done

# Create a configuration file and setup filebeat input
cat << EOF > /etc/logstash/conf.d/02-beats-input.conf
###
input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
    ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
  }
}
EOF

# Add port firewall
ufw allow 5044

# Create a configuration file to add filter for syslog message
cat << EOF > /etc/logstash/conf.d/10-syslog-filter.conf
###
filter {
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}
EOF

# Use grok to parse incoming syslog logs to make it structured and query-able
cat << EOF > /etc/logstash/conf.d/30-elasticsearch-output.conf
###
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    sniffing => true
    manage_template => false
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
EOF

# Test configuration Logstash
echocolor "Kiem tra lai file config logstash"
/opt/logstash/bin/logstash --configtest -f /etc/logstash/conf.d/
sleep 3

# Restart Logstash
echocolor "Khoi dong lai Logstash"
	/etc/init.d/logstash restart
	update-rc.d logstash defaults

# Load Kibana Dashboards (filebeat)
echocolor "Cau hinh Dashboard cho Kibana"
	sleep 3
	mkdir -p /root/kibana
	cd /root/kibana
	curl -L -O https://download.elastic.co/beats/dashboards/beats-dashboards-1.2.2.zip
	apt-get -y install unzip
	unzip beats-dashboards-*.zip
	cd beats-dashboards-*
	./load.sh

# Load Filebeat Index Template in Elasticsearch
echocolor "Thiet lap filebeat index cho elasticsearch"
	sleep 3
	mkdir -p /root/filebeat
	cd /root/filebeat
	curl -O https://gist.githubusercontent.com/thisismitch/3429023e8438cc25b86c/raw/d8c479e2a1adcea8b1fe86570e42abab0f10f364/filebeat-index-template.json
	curl -XPUT 'http://localhost:9200/_template/filebeat?pretty' -d@filebeat-index-template.json

# Gui ssl_certificate tu ELK server toi client.
echocolor "Gui ssl tu ELK server sang client"
	apt-get install sshpass

	# sshpass -p '$PASSWD_CLIENT1' scp -o "StrictHostKeyChecking no" filebeat-index-template.json $USERNAME_CLIENT1@$IP_ELK_CLIENT1:/tmp/
	sshpass -p $PASSWD_CLIENT1 scp -o "StrictHostKeyChecking no" /etc/pki/tls/certs/logstash-forwarder.crt $USERNAME_CLIENT1@$IP_ELK_CLIENT1:/tmp/

echocolor "Hoan thanh cai dai ELK server"