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

# copy the ELK Server's SSL certificate into the appropriate location (/etc/pki/tls/certs)
mkdir -p /etc/pki/tls/certs
cp /tmp/logstash-forwarder.crt /etc/pki/tls/certs/

# Install Filebeat Package
echo "deb https://packages.elastic.co/beats/apt stable main" |  sudo tee -a /etc/apt/sources.list.d/beats.list
	wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	apt-get update -y && apt-get install filebeat -y

# configuration filebeat
filebeatfile=/etc/filebeat/filebeat.yml
test -f $filebeatfile.orgi || cp $filebeatfile $filebeatfile.orgi




