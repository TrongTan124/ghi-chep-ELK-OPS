Trong ELK stack có thành phần Elasticsearch, nhưng triển khai thử nghiệm chúng ta cài đặt theo kiểu All In One (AIO). 
Toàn bộ quá trình cài đặt, cấu hình AIO hệ thống ELK stack đều không nói nhiều về Elasticsearch. Chúng ta chỉ biết nó có nhiệm vụ lưu trữ, đánh chỉ mục, tìm kiếm. 
Nó có rất nhiều đặc điểm mạnh như: Search engine, Distributed, Cluster, Highly Available, Restful API,... Nhưng  khi cài đặt AIO, ta không thấy Elasticsearch có đầy đủ các đặc điểm trên. 
Vậy khi triển khai ELK stack ở mức production (sản phẩm thương mại) thì phải cài đặt, cấu hình Elasticsearch như thế nào để phát huy tất cả các điểm mạnh đã nói. 
Tính phân tán, sẵn sàng, mở rộng được thể hiện ở đâu? Lượng dữ liệu tới hàng Petabyte thì Elasticsearch có còn mạnh nữa không? ....

Có thể ví Elasticsearch như một bộ não của ELK stack. Một bộ não hoạt động tốt sẽ làm cho hệ thống chạy hiệu quả. Trong phần này tôi sẽ tìm hiểu sâu hơn về Elasticsearch:
- Cách lưu trữ.
- Cách tìm kiếm.
- Cách đánh chỉ mục.
- Cách triển khai cluster.
- Và nhiều đặc điểm khác.

Các phần tiếp theo tôi sẽ dựa vào ebook "ElasticSearch Cookbook" để trình bày

# 1. Giới thiệu

Mỗi instance của Elasticsearch được gọi là một node, vài node nhóm lại thành một cluster. Instance có thể là physical server hoặc virtual server.

Khi một node khởi động, nó sẽ có một số action sau:
- đọc file cấu hình elasticsearch.yml
- Nếu node chưa có tên nó sẽ chọn ngẫu nhiên 1 tên
- Elasticsearch khởi động các module và plugin có sẵn trong cài đặt của nó.

Sau khi một node khởi động, nó sẽ tìm kiếm các thành viên khác trong cluster để kiểm tra trạng thái index và shard.

Để 2 node hoặc nhiều hơn được đặt trong 1 cluster, nó phải thỏa mãn vài rule sau:
- phiên bản elasticsearch phải giống nhau
- tên cluster phải giống nhau
- mạng phải cấu hình hỗ trợ broadcast discovery và chúng có thể kết nối với nhau

Thông thường, quản lý một cluster sẽ là master node, có nhiệm vụ chỉ dẫn hành động cho tất cả các node khác, được gọi là secondary node thực hiện nhân bản dữ liệu.

Để phù hợp với hành động write, tất cả các update phải được ghi nhận đầu tiên trên master node sau đó mới nhân bản ra secondary node.

Trong một cluster có nhiều node, nếu master node bị die thì một master-eligible node được bầu chọn để làm master node mới. Phương pháp này cho phép tự động failover (chịu lỗi) 
cho một elasticsearch cluster.

Có 2 chế độ quan trọng trong một Elasticsearch node: non-data node (arbiter) và data container
- Non-data node xử lý các REST và các hành động khác của tìm kiếm. Trong quá trình xử lý: non-data node chịu trách nhiệm phân tán action tới các shard (map) và tổng hợp kết quả từ shard 
(redux) để có thể gửi một phản hồi cuối cùng. Chúng yêu cầu một lượng RAM lớn để: chia tách, gom gộp, thu thập kết quả, lưu bộ nhớ tạm.
- Data node lưu trữ dữ liệu, chúng chứa các shard có nhiệm vụ lưu trữ các chỉ mục văn bản.

Trong cấu hình mặc định, một node gồm cả 2 chế độ arbiter và data container.

Với kiến trúc lớn, sẽ cấu hình vài node làm arbiter có rất nhiều RAM, không có dữ liệu, để giảm lượng tài nguyên yêu cầu cho data node, tăng hiệu năng cho việc tìm kiếm khi sử dụng bộ nhớ 
cục bộ của arbiter.

Khi một node chạy, có rất nhiều service được quản lý bởi chính instance. Các service này cung cấp thêm tính năng cho node như networking, indexing, analyzing

Elasticsearch cung cấp một tập các chức năng có thể mở rộng bằng việc thêm các plugin. Trong quá trình một node khởi động, rất nhiều service yêu cầu được tự động chạy:
- Cluster service: Quản lý trạng thái cluster, kết nối nội bộ node, đồng bộ
- Indexing service: Quản lý tất cả hành động indexing, khởi tạo các active indice và shard.
- Mapping service: Quản lý các loại document được lưu trong cluster
- Network server: Có các service như HTTP REST (port 9200), internal ES protocol (port 9300)
- Plugin Service: Tăng cường các chức năng cơ bản của Elasticsearch
- River service: service chạy trong một cluster, kéo dữ liệu hoặc đẩy dữ liệu.
- Language Scripting Service: Cho phép thêm ngôn ngữ script hỗ trợ Elasticsearch

Mối tương quan giữa Elasticsearch và Relational DB
- Relational DB ==> Databases ==> Tables ==> Rows      ==> Columns
- Elasticsearch ==> Indices   ==> Types  ==> Documents ==> Fields










# Tài liệu tham khảo

Ebook:
- Elasticsearch in Action - Radu Gheorghe, Matthew Lee Hinman, Roy Russo (2016)
- Elasticsearch Indexing - Huseyin Akdogan (2015)
- Mastering Elasticsearch Second Edition - Rafal Kuc, Marek Rogozinski (2015)
- Elasticsearch Server - Third Ed - Rafal Kuc, Marek Rogozinski (2016)
- ElasticSearch Cookbook - Second Edition - Alberto Paro (2015)
- Elasticsearch The Definitive Guide - Clinton Gormley, Zachary Tong (2015)

Một số website Q&A, TIP có thể tham khảo thêm
- [https://www.loggly.com/blog/nine-tips-configuring-elasticsearch-for-high-performance/](https://www.loggly.com/blog/nine-tips-configuring-elasticsearch-for-high-performance/)
- [https://www.infoq.com/articles/elasticsearch-action](https://www.infoq.com/articles/elasticsearch-action)
