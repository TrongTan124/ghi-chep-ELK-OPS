#!/bin/bash

# Ham dinh nghia mau cho cac ban tin in ra man hinh
function echocolor {
	echo -e "\e[1;33m ########## $1 ########## \e[0m"
}

function check_update {
	# cap nhat he thong
	echocolor "Kiem tra va cap nhat he dieu hanh"
	sleep 3

	apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y
}

function install_keepalived {
	echocolor "Cai dat, cau hinh IP VIP"
	sleep 3

	apt-get install keepalived -y
	keepalivedfile=/etc/keepalived/keepalived.conf
	test -f $keepalivedfile.orgi || cp $keepalivedfile $keepalivedfile.orgi

	rm -rf $keepalivedfile
	cat << 'EOF' > $keepalivedfile
	##! Configuration File for keepalived

	vrrp_instance VI_1 {
	    state MASTER
	    interface eth0
	    virtual_router_id 51
	    priority 150
	    advert_int 1
	    authentication {
	        auth_type PASS
	        auth_pass $ place secure password here.
	    }
	    virtual_ipaddress {
	        10.32.75.200
	    }
	}
EOF
	

}

function install_prepare {
	# Cai dat cac goi can thiet
	echocolor "Cai dat cac goi can thiet"

	echocolor "Cai dat CRUDINI de chinh sua cau hinh"
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

	echocolor "Cai dat sshpass"
	apt-get install sshpass

	echocolor "Cai dat JAVA 8 de chay ELK stack"
	sleep 3

	add-apt-repository -y ppa:webupd8team/java
	apt-get update -y

	# silent option
	echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections #silent option
	echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections

	apt-get install oracle-java8-installer -y
	bash -c "echo JAVA_HOME=/usr/lib/jvm/java-8-oracle/bin/ >> /etc/environment"

	echocolor "Kiem tra lai version JAVA sau khi cai dat"

	java -version

	sleep 3
}

function install_elasticsearch {
	# Cai dat Elasticsearch
	echocolor "Cai dat Elasticsearch"
	sleep 3

	mkdir -p /root/elasticsearch
	cd /root/elasticsearch
	wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
	apt-get update -y && apt-get -y install elasticsearch

	echocolor "Chinh sua cau hinh Elasticsearch"
	sleep 3

	elasticsearchfile=/etc/elasticsearch/elasticsearch.yml
	test -f $elasticsearchfile.orgi || cp $elasticsearchfile $elasticsearchfile.orgi		# backup lai file config

	sed -i 's/# network.host: 192.168.0.1/network.host: localhost/g' $elasticsearchfile
	sed -i 's/# node.name: node-1/node.name: "node1"/g' $elasticsearchfile
	sed -i 's/# cluster.name: my-application/cluster.name: clusterops/g' $elasticsearchfile

	# Restart elasticsearch
	echocolor "Khoi dong lai elasticsearch"
	sleep 3
	/etc/init.d/elasticsearch restart
	update-rc.d elasticsearch defaults
}

function install_kibana {
	echocolor "Cai dat Kibana"
	sleep 3

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

	echocolor "Khoi dong lai Kibana"
	sleep 3
	/etc/init.d/kibana restart
	update-rc.d kibana defaults

}

function install_nginx {
	# Cai dat nginx de lam proxy truy cap kibana
	echocolor "Cai dat Nginx de lam proxy xac thuc nguoi dung dang nhap Kibana"
	sleep 3
	apt-get -y install nginx

	# Thiet lap ssl truy cap tu nginx toi kibana
	echo "$KIBANA_USER_LOGIN:`openssl passwd -apr1 $KIBANA_PASSWD_LOGIN`" | sudo tee -a /etc/nginx/htpasswd.users

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

	echocolor "Kiem tra lai cau hinh nginx"
	nginx -t
	sleep 3

	echocolor "Khoi dong lai nginx"
	sleep 3
	/etc/init.d/nginx restart

	# neu firewall on thi add them rule
	ufw allow 'Nginx Full'
	ufw reload
}

function install_logstash {
	# Cai dat Logstash
	echocolor "Cai dat Logstash"
	sleep 3
	mkdir -p /root/Logstash
	cd /root/Logstash

	echo "deb http://packages.elastic.co/logstash/2.3/debian stable main" | sudo tee -a /etc/apt/sources.list
	apt-get update -y && apt-get install logstash -y

	echocolor "Cau hinh Logstash"
	sleep 3

	while [ "$SSL_BOOLEAN" = true ]; do
		mkdir -p /etc/pki/tls/certs
		mkdir -p /etc/pki/tls/private

		if [ $SSL_OPTION = ip_address ]; then
			opensslfile=/etc/ssl/openssl.cnf
			test -f $opensslfile.orgi || cp $opensslfile $opensslfile.orgi

			crudini --set $opensslfile " v3_ca " subjectAltName IP:$IP_VIP_ELK

			cd /etc/pki/tls
			openssl req -config /etc/ssl/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt
			break

		elif [ $SSL_OPTION = fqdn_dns ]; then
			cd /etc/pki/tls
			openssl req -subj '/CN=ELK_server_fqdn/' -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt
			break

		else
			echocolor "Neu ban chon cai dat ssh, ban phai chon ip_address hoac fqdn_dns. Ban hay dien lai option de tiep tuc cai dat."
			read input_option
			SSL_OPTION=$input_option
			SSL_BOOLEAN=true
		fi
	done
}

function config_logstash_filebeat {
	if [ "$FILEBEAT_BOOLEAN" = true ]; then
	cat << 'EOF' > /etc/logstash/conf.d/02-beats-input.conf
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
	ufw reload

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
	fi

	# Test configuration Logstash
	echocolor "Kiem tra lai file config logstash"
	/opt/logstash/bin/logstash --configtest -f /etc/logstash/conf.d/
	sleep 3

	# Restart Logstash
	echocolor "Khoi dong lai Logstash"
	sleep 3
	/etc/init.d/logstash restart
	update-rc.d logstash defaults
}

function config_kibana_dashboard {
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
}

function config_index_filebeat {
	if [ "$FILEBEAT_BOOLEAN" = true ]; then
	echocolor "Thiet lap filebeat index cho elasticsearch"
	sleep 3

	mkdir -p /root/filebeat
	cd /root/filebeat
	curl -O https://gist.githubusercontent.com/thisismitch/3429023e8438cc25b86c/raw/d8c479e2a1adcea8b1fe86570e42abab0f10f364/filebeat-index-template.json
	curl -XPUT 'http://localhost:9200/_template/filebeat?pretty' -d@filebeat-index-template.json
	fi
}

function config_index_packetbeat {
	if [[ "$PACKETBEAT_BOOLEAN" = true ]]; then
	echocolor "Thiet lap packetbeat index cho elasticsearch"
	sleep 3

	mkdir -p /root/packetbeat
	cd /root/packetbeat
	curl -O https://raw.githubusercontent.com/elastic/beats/master/packetbeat/packetbeat.template-es2x.json
	curl -XPUT 'http://localhost:9200/_template/packetbeat' -d@packetbeat.template-es2x.json
	fi
}

function send_ssl_to_client {
	# Gui ssl_certificate tu ELK server toi client.
	echocolor "Gui ssl tu ELK server sang client"

	sshpass -p $PASSWD_CLIENT1 scp -o "StrictHostKeyChecking no" /etc/pki/tls/certs/logstash-forwarder.crt $USERNAME_CLIENT1@$IP_ELK_CLIENT1:/tmp/
}