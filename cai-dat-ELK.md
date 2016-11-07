# 1.Chuẩn bị


# 2. Cài đặt

- Có 02 cách cài đặt
	- Cài đặt thủ công
	- Cài đặt theo script
	
- Phần cài đặt thủ công, tôi thực hiện step by step theo tài liệu tham khảo ở link dưới từ website digitalocean.com

- Phần cài đặt script là tôi tự viết dự trên các bước ở cài đặt thủ công. Có chọn lựa các cách truyền dữ liệu từ client đến ELK server

- Có các hình thức để gửi dữ liệu từ client tới ELK server:
	- Sử dụng beat:
		- Filebeat: đọc file log và gửi
		- Topbeat: lấy dữ liệu về tài nguyên client và gửi
		- Packetbeat: lấy dữ liệu từ các port của tiến trình và gửi
		- winlogbeat: lấy dữ liệu từ log Windows và gửi
	- Sử dụng logstash-forwarder
	
![beats-platform](/images/beats-platform.png)

# Tham khảo
- [https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-elasticsearch-on-ubuntu-14-04](https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-elasticsearch-on-ubuntu-14-04)
- [https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-elk-stack-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-install-elasticsearch-logstash-and-kibana-elk-stack-on-ubuntu-16-04)
- [https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-packetbeat-and-elk-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-packetbeat-and-elk-on-ubuntu-16-04)
- [https://www.digitalocean.com/community/tutorials/how-to-use-logstash-and-kibana-to-centralize-logs-on-centos-6](https://www.digitalocean.com/community/tutorials/how-to-use-logstash-and-kibana-to-centralize-logs-on-centos-6)
- [https://www.elastic.co/guide/index.html](https://www.elastic.co/guide/index.html)
- [https://www.digitalocean.com/community/tutorials/adding-logstash-filters-to-improve-centralized-logging-logstash-forwarder](https://www.digitalocean.com/community/tutorials/adding-logstash-filters-to-improve-centralized-logging-logstash-forwarder)
- [https://www.digitalocean.com/community/tutorials/how-to-use-logstash-and-kibana-to-centralize-and-visualize-logs-on-ubuntu-14-04](https://www.digitalocean.com/community/tutorials/how-to-use-logstash-and-kibana-to-centralize-and-visualize-logs-on-ubuntu-14-04)
