# 1.Chuẩn bị


# 2. Cài đặt

- Có 02 cách cài đặt
	- Cài đặt thủ công
	- Cài đặt theo script
	
- Phần cài đặt thủ công, tôi thực hiện step by step theo tài liệu tham khảo ở [link](https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-elk-stack-on-ubuntu-16-04)

- Phần cài đặt script là tôi tự viết dựa trên các bước ở cài đặt thủ công. Có chọn lựa các cách truyền dữ liệu từ client đến ELK server

- Có các hình thức để gửi dữ liệu từ client tới ELK server:
	- Sử dụng beat:
		- Filebeat: đọc file log và gửi
		- Topbeat: lấy dữ liệu về tài nguyên trên client và gửi
		- Packetbeat: lấy dữ liệu từ các port của tiến trình và gửi
		- winlogbeat: lấy dữ liệu từ log Windows và gửi
	- Sử dụng logstash-forwarder
	
![beats-platform](/images/beats-platform.png)

Các bước cài đặt thủ công
---------------

Trên ELK server:

Trong phần cài đặt của tôi, tôi sử dụng Elasticsearch 2.4.1, Logstash 2.3.4, Kibana 4.5.4.

**Yêu cầu**:
- Hệ điều hành Ubuntu 14.04
- Ram: >= 2GB
- CPU: >= 2
- Chạy các lệnh với quyền root

1. Cài đặt Java 8:

- Add Oracle Java ppa vào apt:
```sh
# add-apt-repository -y ppa:webupd8team/java
```

	- Update package
```sh
# apt-get update -y
```

	- Cài đặt bản stable của Oracle Java 8 bằng lệnh:
```sh
# apt-get -y install oracle-java8-installer
```
	- Trong quá trình cài sẽ hỏi về license, chọn accept để hoàn thành
	
2. Cài đặt Elasticsearch

- Chạy lệnh sau để nhập public GPG key vào apt:
```sh
# wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
```

- Cập nhật package database vào apt lại lần nữa:
```sh
# apt-get update -y
```

- Cài đặt elasticsearch bằng lệnh sau:
```sh
apt-get -y install elasticsearch
```

- Sau khi Elasticsearch cài đặt xong, thực hiện chỉnh sửa file cấu hình
	- Backup lại file cấu hình
```sh
# cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.orgi
```

	- Để chặn truy cập vào Elasticsearch từ bên ngoài qua công 9200, ta bỏ comment và khai báo giá trị sau:
```sh
network.host: localhost
```

	- Cấu hình lại tên cho cluster và node
```sh
node.name: "My First Node"
cluster.name: mycluster1
```

- lưu file cấu hình và khởi động lại Elasticsearch
```sh
# /etc/init.d/elasticsearch restart
```

- Cấu hình để Elasticsearch tự động khởi động cùng hệ thống
```sh
# update-rc.d elasticsearch defaults
```

Cài đặt Kibana
---------------

- Thêm package Kibana vào source list
```sh
echo "deb http://packages.elastic.co/kibana/4.5/debian stable main" | sudo tee -a /etc/apt/sources.list
```

- Update package database vào apt
```sh
#apt-get update -y
```

- Cài đặt Kibana bằng lệnh sau:
```sh
# apt-get -y install kibana
```

- Kibana đã cài xong, thực hiện thay đổi cấu hình
	- Backup lại file cấu hình
```sh
# cp /opt/kibana/config/kibana.yml /opt/kibana/config/kibana.yml.orgi
```

	- Thay đổi địa chỉ truy nhập vào Kibana từ ngoài vào thành chỉ cho local truy cập. Bởi vì sẽ dùng nginx làm proxy cho việc truy cập từ ngoài
```sh
server.host: "localhost"
```

- Lưu file cấu hình và khởi động lại Kibana
```sh
# /etc/init.d/kibana restart
```

- Thiết lập Kibana khởi động cùng hệ điều hành
```sh
# update-rc.d kibana defaults
```

Cài đặt nginx
--------------

Do ta cấu hình Kibana chỉ cho phép truy cập từ local nên sẽ sử dụng nginx để truy cập từ ngoài.

- Cài Nginx bằng lệnh sau:
```sh
# apt-get -y install nginx
```

- Sử dụng openssl tạo user admin cho phép truy cập vào giao diện web của Kibana
```sh
# echo "kibanaadmin:`openssl passwd -apr1`" | sudo tee -a /etc/nginx/htpasswd.users
```

	- Sử dụng lệnh trên sẽ tạo user *kibanaadmin*, password sẽ là pass mà bạn nhập sau khi chạy lệnh trên.
	
- Thực hiện cấu hình Nginx theo file sau để cho phép nginx truy cập vào Kibana

	- Backup lại cấu hình
```sh
# cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.orgi
```

	- Chỉnh sửa lại file thành như sau
```sh
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
```

- File cấu hình Nginx trên sẽ chuyển tất cả các lưu lượng HTTP vào Kibana, Kibana listen tại *localhost:5601*. Nginx sẽ sử dụng htpasswd.users tạo phía trên làm yêu cầu xác thực.

- Kiểm tra cấu hình Nginx và khởi động lại
```sh
# nginx -t
# /etc/init.d/nginx restart
```

**NOTE**: Nếu server sử dụng firewall thì phải mở port cho phép truy cập từ internet.
```sh
# ufw allow 'Nginx Full'
# ufw reload
```

- Hiện tại đã có thể truy cập vào Kibana thông qua Nginx bằng địa chỉ: http://ip_public_elk_server bằng user kibanaadmin, mật khẩu được nhập ở bước trên. 
Nhưng chưa có dữ liệu trong Elasticsearch nên chưa có gì để hiển thị

Cài đặt Logstash
--------------

- Logstash package có sẵn trong repository của Elasticsearch, nên có thể add Logstash vào source list:
```sh
# echo "deb http://packages.elastic.co/logstash/2.3/debian stable main" | sudo tee -a /etc/apt/sources.list
```

- Cập nhật package database
```sh
# apt-get update -y
```

- Cài đặt logstash bằng lệnh sau
```sh
# apt-get install logstash
```

- Logstash đã cài đặt xong nhưng vẫn chưa được cấu hình

Generate SSL Certificates
-----------

Từ client gửi log về server cần được mã hóa dữ liệu. chúng ta sử dụng SSL certificate và key pair. Certifates sử dụng bởi các shipper và xác thực tại ELK server.
Tạo thư mục lưu trữ certificate và private key bằng lệnh sau:
```sh
# mkdir -p /etc/pki/tls/certs
# mkdir /etc/pki/tls/private
```

Có 2 cách gen SSL certificate, nếu bạn có DNS để phân giải địa chỉ IP của ELK server thì dùng DNS hoặc dùng trực tiếp địa chỉ IP của ELK server

**Cách 1: dùng trực tiếp địa chỉ**

- Cần thực hiện add địa chỉ IP của ELK server vào trường *subjectAltName (SAN)* của SSL certificate khi gen. Để làm điều này, mở file cấu hình OpenSSL và làm như sau

	- Backup lại file cấu hình
```sh
cp /etc/ssl/openssl.cnf /etc/ssl/openssl.cnf.orgi
```
	- Tìm [ v3_ca ] và thêm vào dòng dưới. Nhớ thay địa chỉ của ELK server vào
```sh
subjectAltName = IP: ELK_server_private_IP
```

Bây giờ gen SSL certificate và private key tại thư mục (/etc/pki/tls/...) với lệnh sau:
```sh
# cd /etc/pki/tls
# openssl req -config /etc/ssl/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt
```

- Ta sẽ copy file *logstash-forwarder.crt* tới các client thực hiện gửi logs tới Logstash.

**Cách 2: FQDN (DNS)**

Nếu bạn có DNS cho private networking, bạn sẽ tạo một bản ghi chứa địa chỉ ELK Server, domain name sẽ sử dụng trong lệnh sau để gen SSL certificate.

- gen SSL certificate và private key tại thư mục (/etc/pki/tls/...) bằng lệnh sau:
```sh
# cd /etc/pki/tls
# openssl req -subj '/CN=ELK_server_fqdn/' -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt
```
	
	- Thay đổi *ELK_server_fqdn* bằng domain name của bạn.
	
Configure Logstash
----------------

File cấu hình của Logstash có định dạng JSON và đặt tại */etc/logstash/conf.d*. Cấu hình gồm 03 thành phần: inputs, filters, outputs.

Chúng ta sẽ tạo một file cấu hình tên *02-beats-input.conf* để cho shipper filebeat gửi dữ liệu vào:
```sh
# vi /etc/logstash/conf.d/02-beats-input.conf
```

Nhập vào nội dung dưới:
```sh
input {
  beats {
    port => 5044
    ssl => true
    ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
    ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
  }
}
```

Lưu lại file cấu hình, beat sẽ listen trên port 5044 bằng giao thức TCP. chúng ta sẽ sử dụng SSL certificate và private key đã tạo phía trên.

Nếu bạn sử dụng Firewall thì cần phải mở port để cho phép Logstash kết nối port 5044
```sh
# ufw allow 5044
# ufw reload
```

Bây giờ tạo file cấu hình *10-syslog-filter.conf* để lọc các logs được gửi từ syslog
```sh
# vi /etc/logstash/conf.d/10-syslog-filter.conf
```

Chèn vào nội dung dưới:
```sh
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
```

Lưu lại file cấu hình. Bộ lọc sẽ sử dụng nhãn "syslog" để lựa chọn logs đi qua. chúng ta sử dụng grok để phân tích các logs gửi tới thành dạng dữ liệu có cấu trúc và có thể truy vấn.

Cuối cùng ta tạo file cấu hình output *30-elasticsearch-output.conf*:
```sh
# vi /etc/logstash/conf.d/30-elasticsearch-output.conf
```

Chèn vào nội dung dưới:
```sh
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    sniffing => true
    manage_template => false
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
    document_type => "%{[@metadata][type]}"
  }
}
```

Lưu lại file cấu hình. phần output được cấu hình để Logstash lưu trữ các dữ liệu vào trong Elasticsearch tại địa chỉ localhost:9200. 
Nếu bạn muốn thêm các bộ lọc cho Logstash, bạn phải chắc chắn việc tạo tên file phải được sắp xếp ở giữa file cấu hình input và output (giữa 02- và 30-)

Kiểm tra file cấu hình Logstash bằng lệnh sau
```sh
# /opt/logstash/bin/logstash --configtest -f /etc/logstash/conf.d/
```

Sau vài giây sẽ xuất hiện *Configuration OK* nếu không có lỗi. ngược lại bản phải kiểm tra lại file cấu hình của Logstash.

Khởi động lại logstash và cho phép nó khởi động cùng hệ điều hành
```sh
# /etc/init.d/logstash restart
# update-rc.d logstash defaults
```

Load Kibana Dashboards
----------------------

Elastic cung cấp vài Kibana dashboard và Beat index pattern để giúp bạn sử dụng Kibana. Chúng ta sẽ load chúng để sử dụng Filebeat index pattern.

Sử dụng lệnh *curl* để download file về:
```sh
# mkdir /root/beat
# cd /root/beat
# curl -L -O https://download.elastic.co/beats/dashboards/beats-dashboards-1.2.2.zip
```

Cài đặt unzip package với lệnh sau:
```sh
# apt-get -y install unzip
```

Giải nén file
```sh
# unzip beats-dashboards-*.zip
```

Thực hiện load các sample dashboard, visualization và beat index pattern vào Elasticsearch bằng lệnh sau:
```sh
# cd beats-dashboards-*
# ./load.sh
```

Có các index pattern sau sẽ được load:
- packetbeat-*
- topbeat-*
- filebeat-*
- winlobeat-*

Khi bắt đầu sử dụng Kibana, chúng ta sẽ chọn Filebeat index pattern làm mặc định.

Load Filebeat index template in Elasticsearch
---------------------------------------------

Trong phần này, tôi sử dụng Filebeat để ship log tới Elasticsearch nên chúng ta sẽ load Filebeat index template. 
Index template sẽ cấu hình Elasticsearch để phân tích các trường trong Filebeat theo cách nhanh hơn.

Đầu tiên tải Filebeat index template về máy
```sh
# cd /root/beat
# curl -O https://gist.githubusercontent.com/thisismitch/3429023e8438cc25b86c/raw/d8c479e2a1adcea8b1fe86570e42abab0f10f364/filebeat-index-template.json
```

Load template với lệnh sau:
```sh
# curl -XPUT 'http://localhost:9200/_template/filebeat?pretty' -d@filebeat-index-template.json
```

Nếu template được load đúng, sẽ nhìn thấy message sau:
```sh
{
  "acknowledged" : true
}
```

Bây giờ ELK server đã sẵn sàng để nhận dữ liệu bằng shipper Filebeat, chúng ta sẽ cài đặt Filebeat lên client server.

Set up Filebeat (trên Client Servers)
------------------------------------

Trong phần này sẽ cấu hình gửi logs tới Logstash trên ELK server. 

**Copy SSL Certificate**

Trên ELK server, cần copy SSL certificate được tạo ở bước trên tới Client Server, bạn cần thay username và IP tương ứng của client vào:
```sh
ELK Server# scp /etc/pki/tls/certs/logstash-forwarder.crt user@client_server_private_address:/tmp
```

Kiểm tra chắc chắn certificate đã được copy thành công từ ELK Server tới client server. 
Bây giờ, tại Client Server, copy SSL certificate vào thư mục (*/etc/pki/tls/certs*)
```sh
# mkdir -p /etc/pki/tls/certs
# cp /tmp/logstash-forwarder.crt /etc/pki/tls/certs/
```

Install Filebeat Package
------------------------

Trên Client Server, tạo Beats source list:
```sh
# echo "deb https://packages.elastic.co/beats/apt stable main" |  sudo tee -a /etc/apt/sources.list.d/beats.list
```

Nó sử dụng GPG key như Elasticsearch, được cài đặt bằng lệnh sau:
```sh
# wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
```

Cài đặt Filebeat package:
```sh
# apt-get update -y && apt-get install filebeat -y
```

Configure Filebeat
------------------

Bây giờ chúng ta sẽ cấu hình Filebeat để kết nối tới Logstash trên ELK server.

- Backup lại file cấu hình
```sh
# cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.orgi
```

Do file cấu hình của Filebeat là định dạng YAML nên các khoảng trắng rất quan trọng. Chắc chắn bạn sử dụng đúng số khoảng trắng.

Phần đầu của file cấu hình bạn sẽ thấy session *prospectors*, bạn cần khai báo prospectors để nó shipper cụ thể từng log file. Mỗi prospectors được chỉ ra bằng ký tự -

Chúng ta sẽ chỉnh sửa prospectors mặc định để gửi syslog và auth.log tới Logstash. Dưới paths, comment dòng sau - /var/log/*.log . Dòng này sẽ cấu hình để Filebeat gửi mọi file .log trong thư 
mục tới Logstash. Thêm vào 2 mục syslog và auth.log sẽ nhìn thấy file cấu hình như sau:
```sh
...
      paths:
        - /var/log/auth.log
        - /var/log/syslog
       # - /var/log/*.log
...
```

Tìm tới dòng *document_type*; bỏ # ở nó và thay đổi nó thành "syslog".
```sh
...
      document_type: syslog
...
```

Điều này sẽ chỉ ra prospector có type là syslog (type này liên quan tới file cấu hình filter đã tạo tại ELK server)

Nếu bạn gửi các loại file log khác tới ELK server, bạn có thể tạo ra các prospector vào file cấu hình.

Tiếp theo, dưới output section, tìm dòng elasticsearch và comment nó lại. vì chúng ta sử dụng logstash

Tìm tới logstash trong output session, bỏ comment cho #logstash: và bỏ comment cho #host: thay đổi địa chỉ IP hoặc hostname của ELK server
```sh
### Logstash as output
  logstash:
    # The Logstash hosts
    hosts: ["ELK_server_private_IP:5044"]
```

Filebeat kết nối tới Logstash trên ELK server tại port 5044 đã khai báo ở file input phía trên.

Ngay dưới host, thay đổi giá trị của bulk_max_size thành 1024, vì mặc đinh logs sinh ra từ syslog không bao giờ vượt quá 1024. tham khảo tại [đây](https://github.com/hocchudong/Mot-vai-hieu-biet-ve-log)
```sh
bulk_max_size: 1024
```

Tìm đến tls section, bỏ comment nó và bỏ comment cho dòng certificate_authorities, thay đổi thành giá trị ["/etc/pki/tls/certs/logstash-forwarder.crt"]
```sh
...
    tls:
      # List of root certificates for HTTPS server verifications
      certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]
```

Đã cấu hình thành công, giờ lưu lại và restart Filebeat
```sh
# service filebeat restart
# update-rc.d filebeat defaults
```

Hiện tại Filebeat đã gửi log của syslog và auth.log tới Logstash trên ELK server. Lặp lại các bước trên với các server cần thu thập logs khác.

Test Filebeat Installation
--------------------------

Trên ELK server, kiểm tra lại dữ liệu đã nhận từ Filebeat bằng lệnh sau
```sh
# curl -XGET 'http://localhost:9200/filebeat-*/_search?pretty'
```

Nếu nhìn thấy dòng sau là đã có logs gửi về
```sh
...
{
      "_index" : "filebeat-2016.01.29",
      "_type" : "log",
      "_id" : "AVKO98yuaHvsHQLa53HE",
      "_score" : 1.0,
      "_source":{"message":"Feb  3 14:34:00 rails sshd[963]: Server listening on :: port 22.","@version":"1","@timestamp":"2016-01-29T19:59:09.145Z","beat":{"hostname":"topbeat-u-03","name":"topbeat-u-03"},"count":1,"fields":null,"input_type":"log","offset":70,"source":"/var/log/auth.log","type":"log","host":"topbeat-u-03"}
    }
...
```

Nếu output là 0 total hits, Elasticsearch vẫn chưa load được logs, cần kiểm tra lại việc cài đặt xem lỗi ở đâu.

Connect to Kibana
-----------------

Sau khi hoàn thành cài đặt Filebeat trên tất cả các Server cần thu thập logs, sử dụng Kibana đã cài đặt phía trên để xem log đã được thu thập

Đăng nhập bằng username kibanaadmin, password trong phần gen ở mục trước. bạn sẽ thấy giao diện như sau

![kibana1](/images/kibana1.png)

Chọn Filebeat làm dashboard mặc định.

![kibana2](/images/kibana2.png)

Sau đó click vào tab Discover để xem dữ liệu thu thập được

![kibana3](/images/kibana3.png)

----------------

Toàn bộ quá trình cài đặt thủ công trên sử dụng Filebeat làm shipper cho việc gửi logs từ client về server, có nhiều loại shipper khác nữa, có thể tham khảo thêm tại 
[đây](https://github.com/TrongTan124/ghi-chep-ELK-OPS/blob/master/tim-hieu-ve-beat.md) 
	
# Tham khảo
- [https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-elasticsearch-on-ubuntu-14-04](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-elasticsearch-on-ubuntu-14-04)
- [https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-elk-stack-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-elk-stack-on-ubuntu-16-04)
- [https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-packetbeat-and-elk-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-packetbeat-and-elk-on-ubuntu-16-04)
- [https://www.digitalocean.com/community/tutorials/how-to-use-logstash-and-kibana-to-centralize-logs-on-centos-6](https://www.digitalocean.com/community/tutorials/how-to-use-logstash-and-kibana-to-centralize-logs-on-centos-6)
- [https://www.elastic.co/guide/index.html](https://www.elastic.co/guide/index.html)
- [https://www.digitalocean.com/community/tutorials/adding-logstash-filters-to-improve-centralized-logging-logstash-forwarder](https://www.digitalocean.com/community/tutorials/adding-logstash-filters-to-improve-centralized-logging-logstash-forwarder)
- [https://www.digitalocean.com/community/tutorials/how-to-use-logstash-and-kibana-to-centralize-and-visualize-logs-on-ubuntu-14-04](https://www.digitalocean.com/community/tutorials/how-to-use-logstash-and-kibana-to-centralize-and-visualize-logs-on-ubuntu-14-04)
