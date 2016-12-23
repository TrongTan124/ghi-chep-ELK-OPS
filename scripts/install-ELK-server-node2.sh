#!/bin/bash -ex

# import config va function can thiet
source config.cfg
source functions.sh

if [ `id -u` -ne 0 ]; then
   echo "You need root privileges to run this script"
   exit 1
fi

check_update
install_prepare
install_elasticsearch 2
install_kibana
install_nginx 2
install_logstash
config_logstash_filebeat
config_kibana_dashboard
config_index_filebeat
# send_ssl_to_client

echocolor "Hoan thanh cai dai ELK server"
