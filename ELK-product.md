# Require

Trong phần này tôi sẽ thực hiện triển khai ELK ở mức product. Tức là một sản phẩm có thể đáp ứng được các yêu cầu:

- Có khả năng mở rộng 
- Có khả năng tự phục hồi
- Có tính sẵn sàng cao
- ...

Đây là mô hình do tôi tự thực hiện thử nghiệm trong quá trình nghiên cứu về ELK.

Yêu cầu:

- Tối thiểu 03 server (vật lý hoặc ảo)
- Tối thiểu 4GB RAM
- HDD tùy thuộc nhu cầu lưu trữ
- Hệ điều hành ubuntu 14.04 64bit (đây là mô hình thử nghiệm của tôi)

# Cài đặt

Cần thực hiện cài đặt các thành phần sau:

1. Thực hiện update và dist-upgrade hệ điều hành
```sh
# apt-get update -y && apt-get dist-upgrade -y
```

2. Cài đặt các gói chuẩn bị:
	a. Cài đặt Java: tôi sử dụng phiên bản mới nhất là Java 8
```sh
root@ELKServer1:~# java -version 
java version "1.8.0_111"
Java(TM) SE Runtime Environment (build 1.8.0_111-b14)
Java HotSpot(TM) 64-Bit Server VM (build 25.111-b14, mixed mode)
```

	b. Cài đặt keepalive: để tạo IP VIP
```sh
# apt-get install keepalived -y
```

3. Cài đặt Elasticsearch

Tôi sử dụng Elasticsearch version 2.x
```sh
# curl localhost:9200

==>
{
  "name" : "My First Node",
  "cluster_name" : "mycluster1",
  "cluster_uuid" : "6N3SXnpvSzqD4DCqsTc8MA",
  "version" : {
    "number" : "2.4.1",
    "build_hash" : "c67dc32e24162035d18d6fe1e952c4cbcbe79d16",
    "build_timestamp" : "2016-09-27T18:57:55Z",
    "build_snapshot" : false,
    "lucene_version" : "5.5.2"
  },
  "tagline" : "You Know, for Search"
}
```

4. Cài đặt Kibana

Tôi sử dụng Kibana version 4.x
```sh
# /opt/kibana/bin/kibana --version

==>
4.5.4
```

5. Cài đặt Nginx

Lý do cài đặt Nginx để sử dụng chức năng xác thực của webserver khi login truy cập vào Kibana. Bản thân Kibana có một hạn chế là không hỗ trợ xác thực, phân quyền người dùng.
```sh
apt-get -y install nginx
```

6. Cài đặt Logstash

Tôi sử dụng Logstash version 2.x
```sh
# /opt/logstash/bin/logstash --version

==>
logstash 2.3.4
```

**NOTE** Tôi thực hiện cài đặt theo script tự viết, có cả hướng dẫn step-by-step. Bạn có thể tham khảo tại [github](https://github.com/TrongTan124/ghi-chep-ELK-OPS/) của tôi.

# Cấu hình

Cần cài đặt tất cả các bước trên cho 03 server.

1. Thực hiện cấu hình Elasticsearch
----

Elasticsearch là bộ não của ELK, nó có nhiệm vụ lưu trữ, đánh chỉ mục, tìm kiếm kết quả. Trong quá trình cài đặt thử nghiệm all in one thì việc cấu hình Elasticsearch rất ít. Còn với 
product thì cần phải thực hiện cấu hình nó nhiều hơn.

File cấu hình là: /etc/elasticsearch/elasticsearch.yml

- Cấu hình cluster name: Phải đặt cùng một tên cluster cho cả 03 server
```sh
cluster.name: clusterops
```
- Cấu hình node name: Đặt tên cụ thể cho từng node để quản trị dễ dàng hơn. nếu node name không được đặt thì Elasticsearch cũng tự sinh ra một node name ngẫu nhiên trong quá trình hoạt động.
```sh
node.name: "node1"
```
- Cấu hình vai trò cho từng node: Tôi thực hiện đặt dữ liệu trên cả 03 node, các node đều có thể làm master trong cluster.
```sh
node.master: true
node.data: true
```

- Đường dẫn lưu trữ dữ liệu và log: Do tôi để lưu trữ mặc định nên không thay đổi, nếu bạn thay đổi thì có thể đặt đường dẫn cụ thể cho nó
```sh
path.data: /path/to/data
path.logs: /path/to/logs
```

- Cấu hình memory: phần này cần phải biết một chút về cơ chế làm việc của Java. Nhưng cấu hình thì nên không cho phép hệ điều hành tự swap dữ liệu Elasticsearch vào phân vần swap (do 
nó sẽ làm việc truy vấn chậm hơn). Ngoài ra thiết lập lượng RAM để Elasticsearch làm việc bằng 50% dung lượng RAM của hệ điều hành (tối thiểu nên để 2GB, tối đa là 32GB)
```sh
bootstrap.memory_lock: true
ES_HEAP_SIZE
```

- Cấu hình network để giao tiếp ra ngoài qua API hoặc giao tiếp nội bộ các node trong cluster. Port nên để mặc định
```sh
network.host: [_local_, _eth0_]
```

- Cấu hình discovery: Đây là phần cấu hình để các node có thể kết nối và kiểm tra trạng thái kết nối tới nhau. Ngoài ra nó có nhiệm vụ tự điều phối lưu trữ khi gặp lỗi phần cứng trên 
một node nào đó. Tôi có 3 node với IP như dưới, tôi cho phép nó kết nối tới nhau. Và chỉ từ 2 node trở lên mới được phép bầu chọn master trong cluster
```sh
discovery.zen.ping.unicast.hosts: ["172.16.69.92", "172.16.69.93", "172.16.69.90"]
discovery.zen.minimum_master_nodes: 2
```

- Tham số chống việc copy dữ liệu khi chưa đạt được kết nối tới số node tối thiểu. tránh việc bị chiếm tài nguyên băng thông. Có thể không cần cấu hình
```sh
gateway.recover_after_nodes: 2
```

- Một số tham số khác như "node.max_local_storage_nodes" sẽ cho phép primary và replica shard cùng lưu trữ trên 2 node. hay "action.destructive_requires_name" sẽ ngăn việc xóa 
dữ liệu của toàn bộ cluster.

- Optimized cho Elasticsearch: Tăng số lượng file được mở trên hệ điều hành cho user elasticsearch (giá trị ulimit).

2. Thực hiện cấu hình Kibana, Nginx
----

# Tham khảo

- My experience