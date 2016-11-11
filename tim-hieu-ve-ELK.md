# 1. Giới thiệu

ELK là một ứng dụng được phát triển bằng cách kết hợp 03 thành phần có chức năng riêng biệt lại: thu thập + phân tích (Logstash); đánh chỉ mục và tìm kiếm (Elasticsearch); 
thực hiện truy vấn và hiển thị kết quả (Kibana).

Điểm mạnh của ELK là khả năng thu thập, hiển thị, truy vấn theo thời gian thực. Có thể đáp ứng truy vấn một lượng dữ liệu cực lớn.

Workflow:
![elk-infrastructure](/images/elk-infrastructure.png)

# 2. Các thành phần

- Elasticsearch có nhiệm vụ tìm kiếm và lưu trữ dữ liệu

- Logstash có nhiệm vụ làm nơi tập trung log và phân tích dữ liệu

- Kibana hiển thị dữ liệu rất mạnh theo các dạng đồ thị.

# 3. Elasticsearch

- Elasticsearch là một RESTful distributed search engine. Hiểu nôm na là nó cung cấp khả năng tìm kiếm phân tán qua API. Lưu trữ dữ liệu theo dạng NoSQL database (cơ sở dữ liệu 
không có cấu trúc).

- Truy vấn:
	- Elasticsearch cho phép bạn thực thi và kết hợp rất nhiều loại tìm kiếm: có cấu trúc, không cấu trúc, geo, metric theo cách bạn muốn.

- Phân tích:
	- Việc tìm kiếm trong một lượng ít dữ liệu rất dễ dàng, nhưng nếu có 1 tỷ dòng dữ liệu thì thế nào? Elasticsearch cho phép bạn có cái nhìn để khai thác khuynh hướng 
	và các mẫu trong dữ liệu.

- Tốc độ:
	- Elasticsearch rất nhanh, thực sự rất nhanh. Bạn có câu trả lời ngay tức thì với các dữ liệu thay đổi.

- Khả năng mở rộng:
	- Bạn có thể chạy nó trên hàng trăm server với hàng petabyte dữ liệu.
	
- Vận hành dễ dàng:
	- Khả năng co giãn, Độ sẵn sàng cao
	- Dự đoán trước, tin cậy
	- Đơn giản, trong suốt
	
- Có thư viện cho các máy trạm
	- Elasticsearch sử dụng chuẩn RESTful APIs và JSON.
	
## Hiểu như nào là: A Distributed RESTful Search Engine
- Distributed and Highly Available Search Engine
	- Mỗi Index là full shard với một số cấu hình của shard
	- Mỗi shard có một hoặc nhiều replica
	- xử lý đọc và tìm kiến trên mõi replica shard.
	
- Multi Tenant with Multi Types
	- Hỗ trợ nhiều hơn một index
	- Hỗ trợ nhiều loại trên một index
	- Cấu hình index level (số shard, index storage)
	
- Various set of APIs
	- HTTP RESTful API
	- Native Java API
	- Tất cả API thực hiện thao tác node tự động mỗi khi định tuyến lại
	
- Document oriented
	- Không cần định nghĩa trước schema
	- Schema có thể được định nghĩa cho mỗi loại tùy vào quá trình indexing
	
- Tin cậy

- Tìm kiếm (gần) theo thời gian thực

- Xây dựng dựa trên Lucene
	- Mỗi shard là một Lucene index đầy đủ chức năng
	- Tất cả các ưu điểm của Lucene được khai phá thông qua cấu hình/plugin đơn giản.
	
- Hoạt động nhất quán
	- Document level hoạt động thống nhất, độc lập, lâu dài
	
- Open Source under the Apache License, version 2 (“ALv2”)
	
	
# 4. Logstash

Logstash có chức năng phân tích cú pháp của các dòng dữ liệu. Việc phân tích làm cho dữ liệu đầu vào ở một dạng khó đọc, chưa có nhãn thành một dạng dữ liệu có cấu trúc, được gán nhãn.

Khi cấu hình Logstash luôn có 3 phần: Input, Filter, Output.

Bình thường khi làm việc với Logstash, sẽ phải làm việc với Filter nhiều nhất. Filter hiện tại sử dụng Grok để phân tích dữ liệu

# 5. Kibana

Kibana được phát triển riêng cho ứng dụng ELK, thực hiển chuyển đổi các truy vấn của người dùng thành câu truy vấn mà Elasticsearch có thể thực hiện được. 
Kết quả hiển thị bằng nhiều cách: theo các dạng biểu đồ.
	
# Tham khảo
- [https://www.elastic.co/webinars/introduction-elk-stack](https://www.elastic.co/webinars/introduction-elk-stack)
- [https://github.com/elastic/elasticsearch](https://github.com/elastic/elasticsearch)
- []()