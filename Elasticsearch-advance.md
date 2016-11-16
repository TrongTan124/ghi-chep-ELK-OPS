Trong ELK stack có thành phần Elasticsearch, nhưng triển khai thử nghiệm chúng ta cài đặt theo kiểu All In One (AIO). 
Toàn bộ quá trình cài đặt, cấu hình AIO hệ thống ELK stack đều không nói nhiều về Elasticsearch. Chúng ta chỉ biết nó có nhiệm vụ lưu trữ, đánh chỉ mục, tìm kiếm. 
Nó có rất nhiều đặc điểm mạnh như: search engine, distributed, cluster, Highly Available,... Cài đặt AIO, ta không thấy đầy đủ các đặc điểm trên. 
Vậy khi triển khai Elasticsearch ở mức production (sản phẩm thương mại) thì phải cài đặt, cấu hình Elasticsearch như thế nào để phát huy tất cả các điểm mạnh đã nói. 
Tính phân tán, sẵn sàng, mở rộng được thể hiện ở đâu? Lượng dữ liệu tới hàng Petabyte thì Elasticsearch có còn mạnh nữa không? ....

Trong phần này tôi sẽ tìm hiểu sâu hơn về Elasticsearch:
- Cách lưu trữ.
- Cách tìm kiếm.
- Cách đánh chỉ mục.
- Cách triển cluster.
- Và nhiều đặc điểm khác.













# Tài liệu tham khảo

- Elasticsearch in Action - Radu Gheorghe, Matthew Lee Hinman, Roy Russo (2016).pdf
- Elasticsearch Indexing - Huseyin Akdogan (2015).pdf
- Mastering Elasticsearch Second Edition - Rafal Kuc, Marek Rogozinski (2015).pdf
- Elasticsearch Server - Third Ed - Rafal Kuc, Marek Rogozinski (2016).pdf
- ElasticSearch Cookbook - Second Edition - Alberto Paro (2015).pdf
- Elasticsearch The Definitive Guide - Clinton Gormley, Zachary Tong (2015).pdf