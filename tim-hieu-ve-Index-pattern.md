# 1. Index pattern là gì? Tại sao phải dùng?

ELK cần sử dụng các "beat" để làm shipper giúp gửi các loại dữ liệu từ client tới Logstash.

Các beat index pattern cần được cài đặt trên cả ELK server và các client. Trên ELK server, các beat sẽ kết hợp với các thành phần để lọc dữ liệu, đánh chỉ mục, hiển thị.

# 2. Các index pattern thường dùng

- [packetbeat-]YYYY.MM.DD
- [topbeat-]YYYY.MM.DD
- [filebeat-]YYYY.MM.DD
- [winlogbeat-]YYYY.MM.DD

Windows sử dụng nxlog để gửi log từ Client đến ELK server

---------
## Filebeat


---------
## Packetbeat


---------
## Topbeat

Topbeat là một trong vài "Beats" data shipper, thực hiện việc gửi các loại dữ liệu các nhau từ Server tới Elasticsearch. Cho phép bạn thu thập thông tin về CPU, memory, process activity.

**Yêu câu**:
- Đã cài đặt ELK

---------
## Winlobeat


---------
# 3. Cài đặt, cấu hình
## a. Filebeat


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

# Tham khảo
- [https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-topbeat-and-elk-on-ubuntu-14-04](https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-topbeat-and-elk-on-ubuntu-14-04)
- [https://www.elastic.co/guide/en/beats/filebeat/current/how-filebeat-works.html](https://www.elastic.co/guide/en/beats/filebeat/current/how-filebeat-works.html)

