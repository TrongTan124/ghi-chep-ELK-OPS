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
echocolor "Cau hinh Filebeat"
	sleep 3
	filebeatfile=/etc/filebeat/filebeat.yml
	test -f $filebeatfile.orgi || cp $filebeatfile $filebeatfile.orgi

#	sed -i_bac -e '/- \/var/ s/^/#/' -e '/ paths:/a \        - /var/log/messages' -e '/ paths:/a \        - /var/log/secure' -e 's/#document_type:.*$/document_type: syslog/' -e '/elasticsearch:/,/# Logstash/ s/^/#/' -e 's/#logstash:/logstash:/' -e \"/logstash:/,+2 s/#hosts: \[\\\"localhost:/hosts: \[\\\"$IP_ELK_SERVER:/\" -e '/hosts.*5044/a \    bulk_max_size: 1024' -e '/logstash:/,+30 s/#tls:/tls:/' -e '/ tls:/,+5 s/#certificate_authorities:.*/certificate_authorities: \[\"\/etc\/pki\/tls\/certs\/logstash-forwarder.crt\"\]/' $filebeatfile

sed -i_bac -e '/- \/var/ s/^/#/' -e '/ paths:/a \        - /var/log/messages' -e '/ paths:/a \        - /var/log/secure' -e 's/#document_type:.*$/document_type: syslog/' -e '/elasticsearch:/,/# Logstash/ s/^/#/' -e 's/#logstash:/logstash:/' -e "/logstash:/,+2 s/#hosts: \[\"localhost:/hosts: \[\":/" -e '/hosts.*5044/a \    bulk_max_size: 1024' -e '/logstash:/,+30 s/#tls:/tls:/' -e '/ tls:/,+5 s/#certificate_authorities:.*/certificate_authorities: \["\/etc\/pki\/tls\/certs\/logstash-forwarder.crt"\]/' $filebeatfile

# Restart filebeat
echocolor "Khoi dong lai filebeat"
	sleep 3
	service filebeat restart
	update-rc.d filebeat defaults

echocolor "install ELK client done"