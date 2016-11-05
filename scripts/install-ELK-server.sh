#!/bin/bash -ex

function echocolor {
	echo -e "\e[1;33m ########## $1 ########## \e[0m"
}

# cap nhat he thong
echocolor "Kiem tra va cap nhat he dieu hanh"
sleep 5

apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y

# Cai dat cac goi can thiet
echocolor "Cai dat cac goi can thiet"
echocolor "Cai dat java 8"
	sleep 3
	add-apt-repository -y ppa:webupb8team/java
	apt-get update -y
	# silent option
	echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo debconf-set-selections #silent option
	echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 seen true" | debconf-set-selections
	# install
	apt-get install oracle-java8-installer -y

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
echo "kibanaadmin:`openssl passwd -apr1 $KIBANA_PASSWD_LOGIN`" | sudo tee -a /etc/nginx/htpasswd.users

# Cau hinh nginx
echocolor "Chinh sua cau hinh Nginx"
	sleep 3
	nginxfile=/etc/nginx/sites-available/default
	test -f $nginxfile.orgi || cp $nginxfile $nginxfile.orgi 	# backup lai file configuration
	rm -rf $nginxfile
cat << EOF > $nginxfile
server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
        root /usr/share/nginx/html;
        index index.html index.htm;
        server_name opselk.com;
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

