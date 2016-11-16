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

# 1. 











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
