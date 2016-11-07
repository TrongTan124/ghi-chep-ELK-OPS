# 1. Index pattern là gì? Tại sao phải dùng?

ELK cần sử dụng các "beat" để làm shipper giúp gửi các loại dữ liệu từ client tới Logstash.

Các beat index pattern cần được cài đặt trên cả ELK server và các client. Trên ELK server, các beat sẽ kết hợp với các thành phần để lọc dữ liệu, đánh chỉ mục, hiển thị.

# 2. Các index pattern thường dùng

- [packetbeat-]YYYY.MM.DD
- [topbeat-]YYYY.MM.DD
- [filebeat-]YYYY.MM.DD
- [winlogbeat-]YYYY.MM.DD

# Tham khảo
- [https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-topbeat-and-elk-on-ubuntu-14-04](https://www.digitalocean.com/community/tutorials/how-to-gather-infrastructure-metrics-with-topbeat-and-elk-on-ubuntu-14-04)
- []()
