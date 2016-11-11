# 1. Beat là gì? Tại sao phải dùng?

Beats is the platform for single-purpose data shippers. They install as lightweight agents and send data from hundreds or thousands of machines to Logstash or Elasticsearch.

ELK cần sử dụng các "beat" để làm shipper giúp gửi các loại dữ liệu từ client tới Server.

Các beat index pattern cần được cài đặt trên cả ELK server và các client. Trên ELK server, các beat sẽ kết hợp với các thành phần để lọc dữ liệu, đánh chỉ mục, hiển thị.

# 2. Các index pattern thường dùng

- [packetbeat-]YYYY.MM.DD	: thực hiện gửi dữ liệu capture từ các port về server
- [topbeat-]YYYY.MM.DD	:
- [filebeat-]YYYY.MM.DD	: thực hiện load file, đọc và gửi các dữ liệu mới về server
- [winlogbeat-]YYYY.MM.DD

Windows sử dụng nxlog để gửi log từ Client đến ELK server

---------
## Filebeat

Check version filebeat
```sh
# /usr/bin/filebeat -version
filebeat version 1.3.1 (amd64)
```

---------
## Packetbeat

Check version packetbeat
```sh
# /usr/bin/packetbeat -version
packetbeat version 1.3.1 (amd64)
```

Tham khảo cài đặt packetbeat làm shipper tại [đây](https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-packetbeat-and-elk-on-ubuntu-16-04)

Các shipper có thể hoạt động độc lập với nhau trên cùng một server. 

Currently, Packetbeat supports the following protocols:
```sh
ICMP (v4 and v6)
DNS
HTTP
Mysql
PostgreSQL
Redis
Thrift-RPC
MongoDB
Memcache
```

Cách cấu hình packetbeat có thể tham khảo tại [đây](https://www.elastic.co/guide/en/beats/packetbeat/1.3/configuration-protocols.html)

Hạn chế của packetbeat là đang config sẵn các port theo template, mục đích của template dùng để đánh chỉ mục trong Elasticsearch và Kibana.

Nếu muốn add thêm port của các giao thức khác, cần phải chỉnh sửa lại file template.json có sẵn, add thêm các trường vào, xóa template có sẵn và import lại.

Tham khảo thêm các cấu hình tại [đây](https://github.com/elastic/beats/tree/master/packetbeat)

---------
## Topbeat

Topbeat là một trong các "Beats" data shipper, thực hiện việc gửi các loại dữ liệu các nhau từ Server tới Elasticsearch. Cho phép bạn thu thập thông tin về CPU, memory, process activity.

**Yêu cầu**:
- Đã cài đặt ELK

Link cài đặt tham khảo tại [đây](https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-topbeat-and-elk-on-ubuntu-14-04)

Có một chút thay đổi, do topbeat đã được đổi thành metricbeat nên lúc get file json về, phải dùng lệnh sau:
```sh
#curl -O https://raw.githubusercontent.com/elastic/beats/master/metricbeat/metricbeat.template-es2x.json
```

Thực hiện input template vào elasticsearch
```sh
# curl -XPUT 'http://localhost:9200/_template/topcbeat?pretty' -d@metricbeat.template-es2x.json

==>
{
  "acknowledged" : true
}
```

---------
## Winlobeat


---------
# 3. Cài đặt, cấu hình

## a. Filebeat

- [Cấu hình filebeat](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-configuration-details.html#_level)

## b. Packetbeat


## c. Topbeat

Load Kibana Dashboards on ELK Server
----

Elastic cung cấp vài Kibana dashboard và Beat index pattern có thể sử giúp bạn bắt đầu với Kibana. Nếu không sử dụng dashboard trong bài này, có thể  
sử dụng Filebeat index pattern.

download the sample dashboards archive to your home directory
```sh
# cd ~
# curl -L -O https://download.elastic.co/beats/dashboards/beats-dashboards-1.1.0.ziphttps://download.elastic.co/beats/dashboards/beats-dashboards-1.1.0.zip
```

## d. Winlobeat

# TIP fix bug

Filebeat
----
The registry file controls where the process reads from each time it opens the file
Make sure to stop filebeat, remove the registry file and start it again so it starts sending from scratch

- Trường hợp filebeat không thực hiện load log và send tới logstash, cần dừng filebeat
```sh
# /etc/init.d/filebeat stop
```
-  xóa file registry
```sh
# rm -rf /var/lib/filebeat/registry
```
- Sau đó restart lại filebeat:
```sh
# /etc/init.d/filebeat start
```


Trường hợp filebeat để cấu hình mặc định sẽ send log vào file /var/log/syslog. nên sửa dòng cấu hình tại /etc/filebeat/filebeat.yml đoạn sau:
```sh
logging:
  to_syslog: false
  to_files: true
  files:
    path: /var/log/myfilebeat
    name: myfilebeat
    rotateeverybytes: 1048576000 # = 1GB
    keepfiles: 7
  selectors: ["*"]
  level: info
```

----

- Đây là file cấu hình của tôi khi config filebeat
```sh
root@controller1:/etc/filebeat# cat filebeat.yml |egrep -v "^$|^#|^  #|^    #|^      #|^        #"
filebeat:
  prospectors:
    -
      paths:
        - /var/log/neutron/*.log
      encoding: utf-8
      input_type: log
      fields:
        level: debug
      document_type: neutron
  registry_file: /var/lib/filebeat/registry
output:
  logstash:
    hosts: ["172.16.69.90:5044"]
    worker: 1
    bulk_max_size: 2048
    tls:
      certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]
shipper:
  name: ctl_neutron
  tags: ["neutron"]
logging:
  to_syslog: false
  to_files: true
  files:
    path: /var/log/myfilebeat
    name: myfilebeat
    rotateeverybytes: 1048576000 # = 1GB
    keepfiles: 7
  selectors: ["*"]
  level: info
```

- Cấu hình với Packetbeat
```sh
root@controller1:/etc/packetbeat# cat packetbeat.yml |egrep -v "^$|^#|^  #|^    #|^      #|^        #"
interfaces:
  device: any
protocols:
  dns:
    ports: [53]
    include_authorities: true
    include_additionals: true
  http:
    ports: [80, 8080, 8000, 5000, 8002, 35357]
  memcache:
    ports: [11211]
  mysql:
    ports: [3306]
  pgsql:
    ports: [5432]
  redis:
    ports: [6379]
  thrift:
    ports: [9090]
  mongodb:
    ports: [27017]
output:
  logstash:
    hosts: ["172.16.69.90:5044"]
    worker: 1
    bulk_max_size: 2048
    tls:
      certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]
shipper:
  name: packetbeat_elkserver1
  tags: ["packet_elk1"]
logging:
  to_syslog: false
  to_files: true
  files:
    path: /var/log/mypacketbeat
    name: mypacketbeat
    rotateeverybytes: 1048576000 # = 1GB
    keepfiles: 7
  selectors: ["*"]
  level: info
```

- Cấu hình với topbeat
```sh
root@controller1:/etc/topbeat# cat topbeat.yml |egrep -v "^$|^#|^  #|^    #|^      #|^        #"
input:
  period: 10
  procs: [".*"]
  stats:
    system: true
    process: true
    filesystem: true
    cpu_per_core: false
output:
  logstash:
    hosts: ["172.16.69.90:5044"]
    worker: 1
    bulk_max_size: 2048
    tls:
      certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]
shipper:
  name: topbeat
  tags: ["topneat_elk"]
logging:
  to_syslog: false
  to_files: true
  files:
    path: /var/log/mytopbeat
    name: mytopbeat
    rotateeverybytes: 1048576000 # = 1GB
    keepfiles: 7
  selectors: ["*"]
  level: info
```

# Tham khảo
- [https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-topbeat-and-elk-on-ubuntu-14-04](https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-topbeat-and-elk-on-ubuntu-14-04)
- [https://www.elastic.co/guide/en/beats/filebeat/current/how-filebeat-works.html](https://www.elastic.co/guide/en/beats/filebeat/current/how-filebeat-works.html)

