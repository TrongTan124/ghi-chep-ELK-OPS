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
	apt-get install oracle-java8-installer -y

# Cai dat Elasticsearch
echocolor "Cai dat Elasticsearch"
	sleep 3
	mkdir -p /root/elasticsearch
	cd /root/elasticsearch
	wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
	echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
	apt-get update -y
	apt-get -y install elasticsearch

# Cau hinh elasticsearch
elasticsearchfile = /etc/elasticsearch/elasticsearch.yml

test -f $elasticsearchfile.orgi || cp $elasticsearchfile $elasticsearchfile.orgi

