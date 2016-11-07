#!/bin/bash

# reference: https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-elk-stack-on-centos-7#set-up-filebeat-(add-client-servers)

# ==================== Configure_Repositories function ==============================
configure_repo() {
tput setaf 2; echo "Configuring Repositories..."; tput sgr 0
echo
# ---------------------------------------------------------------------
rpm --import http://packages.elastic.co/GPG-KEY-elasticsearch
# ---------------------------------------------------------------------
printf "[elasticsearch-2.x] \nname=Elasticsearch repository for 2.x packages \nbaseurl=http://packages.elastic.co/elasticsearch/2.x/centos \ngpgcheck=1 \ngpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch \nenabled=1 \n" > /etc/yum.repos.d/elasticsearch.repo
printf "[kibana-4.4] \nname=Kibana repository for 4.4.x packages \nbaseurl=http://packages.elastic.co/kibana/4.4/centos \ngpgcheck=1 \ngpgkey=http://packages.elastic.co/GPG-KEY-elasticsearch \nenabled=1 \n" > /etc/yum.repos.d/kibana.repo
printf "[nginx] \nname=nginx repo \nbaseurl=http://nginx.org/packages/rhel/6/x86_64/ \ngpgcheck=0 \nenabled=1 \n" > /etc/yum.repos.d/nginx.repo
printf "[logstash-2.2] \nname=logstash repository for 2.2 packages \nbaseurl=http://packages.elasticsearch.org/logstash/2.2/centos \ngpgcheck=1 \ngpgkey=http://packages.elasticsearch.org/GPG-KEY-elasticsearch \nenabled=1 \n" > /etc/yum.repos.d/logstash.repo
# ---------------------------------------------------------------------
tput setaf 2; echo "Downloading prerequisites for ELK stack..."; tput sgr 0
cd $ELK_DOWNLOAD_FILES
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u65-b17/jdk-8u65-linux-x64.rpm"
curl -L -O https://download.elastic.co/beats/dashboards/beats-dashboards-1.1.0.zip
curl -O https://gist.githubusercontent.com/thisismitch/3429023e8438cc25b86c/raw/d8c479e2a1adcea8b1fe86570e42abab0f10f364/filebeat-index-template.json
}

# ==================== Installing Prerequisites function ==============================
install_components() {
tput setaf 2; echo "Installing required components for ELK stack..."; tput sgr 0
sed -i s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
yum clean all >>$INSTALL_LOG
cd $ELK_DOWNLOAD_FILES
yum install jdk-8u65-linux-x64.rpm -y 2>>$INSTALL_LOG >>$INSTALL_LOG

x=("elasticsearch" "kibana" "nginx" "httpd-tools" "logstash")
y=("elasticsearch-2.x" "kibana-4.4" "nginx" "null" "logstash-2.2")
for i in {0..4}
        do
                install_check
done

}

install_check() {
yum list installed ${x[$i]} 2>>$INSTALL_LOG >>$INSTALL_LOG

if [ "$?" = "0" ]; then
        tput setaf 2; echo "Application ${x[$i]} is already Installed...";tput sgr 0
else
        tput setaf 1; echo "Installing Application ${x[$i]} ...";tput sgr 0
        install_app
fi
}

install_app() {
if [ "$i" = "3" ] ; then
        yum install ${x[$i]} -y >>$INSTALL_LOG

else
        yum --enablerepo="${y[$i]}" install ${x[$i]} -y >>$INSTALL_LOG
fi

if [ "$?" = "0" ]; then
        tput setaf 2; echo "Application ${x[$i]} Installed successfully...";tput sgr 0
else
        error_exit
fi
}

# ==================== Configuring Components function ==============================
config_components() {
tput setaf 2; echo "Configuring ELK Components..."; tput sgr 0
config_elastic
config_kibana
config_nginx
config_ssl
config_logstash
load_kibana
load_filebeat
config_firewall
}

# ==================== Configure Elastic Search function ==============================
config_elastic() {
sed -i_bac 's/#.*network.host.*$/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml
chkconfig --add elasticsearch
service elasticsearch start
tput setaf 2; echo "Configured ElasticSearch successfully..."; tput sgr 0
}

# ==================== Configure Kibana function ==============================
config_kibana() {
sed -i_bac 's/#.*server.host.*$/server.host: "localhost"/' /opt/kibana/config/kibana.yml
chkconfig --add kibana
service kibana start
tput setaf 2; echo "Configured Kibana successfully..."; tput sgr 0
}

# ==================== Configure Nginx function ==============================
config_nginx() {
tput setaf 2; echo "Enter a password for Kibana Administrator User (kibanaadmin):"; tput sgr 0
htpasswd -c /etc/nginx/htpasswd.users kibanaadmin
cp -p /etc/nginx/nginx.conf{,.bak}
printf "user  nginx; \n worker_processes  1; \n error_log  /var/log/nginx/error.log warn; \n pid        /var/run/nginx.pid; \n events { \n     worker_connections  1024; \n } \n http { \n     include       /etc/nginx/mime.types; \n     default_type  application/octet-stream; \n     log_format  main  '$remote_addr - $remote_user [$time_local] "$request" ' \n                       '$status $body_bytes_sent "$http_referer" ' \n                       '"$http_user_agent" "$http_x_forwarded_for"'; \n     access_log  /var/log/nginx/access.log  main; \n     sendfile        on; \n     #tcp_nopush     on; \n     keepalive_timeout  65; \n     #gzip  on; \n     include /etc/nginx/conf.d/*.conf; \n } \n" > /etc/nginx/nginx.conf
echo -e "server {\n    listen 80;\n    server_name $SERVER_NAME;\n    auth_basic \"Restricted Access\";\n    auth_basic_user_file /etc/nginx/htpasswd.users;\n    location / {\n        proxy_pass http://localhost:5601;\n        proxy_http_version 1.1;\n        proxy_set_header Upgrade \$http_upgrade;\n        proxy_set_header Connection 'upgrade';\n        proxy_set_header Host \$host;\n        proxy_cache_bypass \$http_upgrade;        \n    }\n}\n" > /etc/nginx/conf.d/kibana.conf
chkconfig --add nginx
service nginx start
tput setaf 2; echo "Configured Nginx successfully..."; tput sgr 0
}

# ==================== SSL Configuration function ==============================
config_ssl() {
cp -p /etc/pki/tls/openssl.cnf{,.bak}
sed -i_bac "/^\[ v3_ca \]/a \subjectAltName = IP: $SERVER_IP" /etc/pki/tls/openssl.cnf
cd /etc/pki/tls
openssl req -config /etc/pki/tls/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt >>$INSTALL_LOG
tput setaf 2; echo "Configured SSL successfully..."; tput sgr 0
}

# ==================== Logstash Configuration function ==============================
config_logstash() {
echo -e 'input { \n   beats { \n     port => 5044 \n     ssl => true \n     ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt" \n     ssl_key => "/etc/pki/tls/private/logstash-forwarder.key" \n   } \n } \n' > /etc/logstash/conf.d/02-beats-input.conf
echo -e 'filter {\n   if [type] == "syslog" {\n     grok {\n       match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }\n       add_field => [ "received_at", "%{@timestamp}" ]\n       add_field => [ "received_from", "%{host}" ]\n     }\n     syslog_pri { }\n     date {\n       match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]\n     }\n   }\n }\n' > /etc/logstash/conf.d/10-syslog-filter.conf
echo -e 'output {       \n   elasticsearch {    \n     hosts => ["localhost:9200"]      \n     sniffing => true \n     manage_template => false \n     index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"   \n     document_type => "%{[@metadata][type]}"    \n   }  \n }    \n' > /etc/logstash/conf.d/30-elasticsearch-output.conf
tput setaf 3; echo "Checking Configuration of Logstash..."; tput sgr 0
service logstash configtest
chkconfig --add logstash
service logstash start
tput setaf 2; echo "Configured Logstash successfully..."; tput sgr 0
}

# ==================== Load Kibana Dashboard function ==============================
load_kibana() {
tput setaf 3; echo "Load Kibana Dashboard..."; tput sgr 0
cd $ELK_DOWNLOAD_FILES
unzip beats-dashboards-*.zip >>$INSTALL_LOG
cd beats-dashboards-*
sh ./load.sh >>$INSTALL_LOG
tput setaf 3; echo "Kibana Dashboard loaded..."; tput sgr 0
}

# ==================== Load Filebeat function ==============================
load_filebeat() {
tput setaf 6; echo "Load File beat..."; tput sgr 0
cd $ELK_DOWNLOAD_FILES
curl -XPUT 'http://localhost:9200/_template/filebeat?pretty' -d@filebeat-index-template.json
tput setaf 6; echo "ELK Server is ready to receive Filebeat data, let's move onto setting up Filebeat on each client server."; tput sgr 0
tput setaf 6; tput bold; printf "Connect to Kibana DashBoard using link \"http://`uname -n`\"\nAfter entering the "kibanaadmin" credentials, you should see a page prompting you to configure a default index pattern.\n"; tput sgr 0
}

# ==================== Configure firewall function ==============================
config_firewall() {
tput setaf 1; echo "Configuring firewall on ELK Server..."; tput sgr 0
for p in 5044 9200 5601 80
        do
                iptables -I INPUT -j ACCEPT -p tcp --dport $p >>$INSTALL_LOG
                iptables -I INPUT -j ACCEPT -p udp --dport $p >>$INSTALL_LOG
                iptables -I OUTPUT -j ACCEPT -p tcp --dport $p >>$INSTALL_LOG
                iptables -I OUTPUT -j ACCEPT -p udp --dport $p >>$INSTALL_LOG
        done
/etc/init.d/iptables save
/etc/init.d/iptables restart
tput setaf 2; echo "Firewall is configured successfully..."; tput sgr 0
}

# ==================== Configure Client function ==============================
config_client()
{
tput setaf 2; read -rp "Enter Client Server Private IP: " CLIENT_IP ; tput sgr 0
ssh-keygen -t rsa -f /root/.ssh/id_rsa -q -P ""
tput setaf 2; echo "Enter credentials of Client Server:" ; tput sgr 0
ssh-copy-id $CLIENT_IP
echo "Installation log of Client Server $CLIENT_IP:" >> $INSTALL_LOG
scp /etc/pki/tls/certs/logstash-forwarder.crt root@$CLIENT_IP:/tmp >> $INSTALL_LOG
ssh $CLIENT_IP "mkdir -p /etc/pki/tls/certs; cp /tmp/logstash-forwarder.crt /etc/pki/tls/certs/"
tput setaf 2; echo "Copied SSL Certficate..."
echo "Installing Filebeat Package on Client Server..."; tput sgr 0
ssh $CLIENT_IP "rpm --import http://packages.elastic.co/GPG-KEY-elasticsearch; echo -e '[beats]\nname=Elastic Beats Repository\nbaseurl=https://packages.elastic.co/beats/yum/el/\$basearch\nenabled=1\ngpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch\ngpgcheck=1\n' > /etc/yum.repos.d/elastic-beats.repo; yum -y install filebeat" >> $INSTALL_LOG

if [ "$?" = "0" ]; then
        echo -e '#!/bin/bash' > /tmp/t.sh
        echo -e "sed -i_bac -e '/- \/var/ s/^/#/' -e '/ paths:/a \        - /var/log/messages' -e '/ paths:/a \        - /var/log/secure' -e 's/#document_type:.*$/document_type: syslog/' -e '/elasticsearch:/,/# Logstash/ s/^/#/' -e 's/#logstash:/logstash:/' -e \"/logstash:/,+2 s/#hosts: \[\\\"localhost:/hosts: \[\\\"$SERVER_IP:/\" -e '/hosts.*5044/a \    bulk_max_size: 1024' -e '/logstash:/,+30 s/#tls:/tls:/' -e '/ tls:/,+5 s/#certificate_authorities:.*/certificate_authorities: \[\"\/etc\/pki\/tls\/certs\/logstash-forwarder.crt\"\]/' /etc/filebeat/filebeat.yml\nexit" >>/tmp/t.sh
        scp /tmp/t.sh $CLIENT_IP:/tmp >> $INSTALL_LOG
        ssh $CLIENT_IP "sh /tmp/t.sh; service filebeat start; chkconfig --add filebeat;"
        tput setaf 2 ; echo "Configured client successfully..."; tput sgr 0
else
        error_exit
fi

}

# ==================== Exit function ==============================
function error_exit()
{
        tput setaf 7; tput setab 1; echo "Unknown Error occured, check installation log located @ $INSTALL_LOG for more information";tput sgr 0
        exit 1
}

# ========================= BEGIN ==========================
# ========================================================
# ========================================================

# ========================= VARIABLES INITIALIZATION ==========================
mkdir /tmp/elk_downloads 2>/dev/null
ELK_DOWNLOAD_FILES=/tmp/elk_downloads
SERVER_NAME=$(uname -n)
touch /tmp/elk_downloads/install_log
INSTALL_LOG=/tmp/elk_downloads/install_log
tput setaf 2; read -rp "Enter ELK Server Private IP: " SERVER_IP; tput sgr 0
#read -rp "Enter Client Server Private IP: " CLIENT_IP

# ========================= FUNCTIONS INVOCATIONS ==========================

    BG_BLUE="$(tput setab 4)"
    BG_BLACK="$(tput setab 0)"
    FG_GREEN="$(tput setaf 2)"
    FG_WHITE="$(tput setaf 7)"

    # Screen size
    row=$(tput lines)
    col=$(tput cols)

    # Save screen
    tput smcup

    # Display menu until selection == 0
    while [[ $REPLY != 0 ]]; do
      echo -n ${BG_BLUE}${FG_WHITE}
      clear
      tput sc; tput cup $((row/3)) $((col/3)); tput setab 1; tput bold; tput setaf 7; printf "Improvisation: aljoantony@gmail.com\n"; tput rc
    cat<<EOF
    ==============================
      ELK Stack Installation Menu
    ------------------------------
    Please enter your choice:
    (1) Configure repo
    (2) Install Components
    (3) Configure Components
    (4) Configure Client
           (0)Quit
    ------------------------------
EOF
      read -p "Enter selection [0-4] > " selection

      # Clear area beneath menu
      tput cup 10 0
      echo -n ${BG_BLACK}${FG_GREEN}
      tput ed
      tput cup 11 0
      tput sc; tput cup $((row/3)) $((col/3)); tput setab 1; tput bold; tput setaf 7; printf "Improvisation: aljoantony@gmail.com\n"; tput rc
      # Act on selection
      case $selection in
        1)  configure_repo
            ;;
        2)  install_components
            ;;
        3)  config_components
            ;;
        4)  config_client
            ;;
        0)  break
            ;;
        *)  echo "Invalid entry."
            ;;
      esac
      printf "\n\nPress any key to continue."
      read -n 1
    done

    # Restore screen
    tput rmcup

# ========================= END ==========================
# =======================================================
# =======================================================
