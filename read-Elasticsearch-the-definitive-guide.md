# Giới thiệu


# Chapter 1


# Chapter 2: Life inside a cluster

Trong chương này, chúng ta sẽ tìm hiểu về cluster, nodes, shards để mở rộng khi cần và chắc chắn rằng dữ liệu chúng ta được an toàn khi phần cứng lỗi.

An empty cluster
----

Khi cài đặt xong một single node mà không có data, không có indicex, cluster sẽ như sau:

![read-defi-single-node](/images/read-defi-single-node.png)

A cluster with one empty node

Một cluster sẽ bầu chọn một node thành master node, nó có nhiệm vụ quản lý việc tạo và xóa index, hay thêm vào hoặc xóa bỏ một node trong cluster.

Master node không liên quan tới sự thay đổi của document hay các yêu cầu tìm kiếm, nghĩa là một master node sẽ không trở thành nút thắt cổ chai khi lưu lượng tăng lên.

Mọi node đều có thể trở thành master node, trong ví dụ trên, cluster chỉ có một node thì nó sẽ thực hiện vai trò của master node.

Người dùng có thể giao tiếp với mọi node trong cluster, bao gồm cả master node. mọi node đều biết được document lưu tại đâu và chuyển tiếp yêu cầu thẳng tới node chứa dữ liệu cần tìm kiếm. 
Ở đây, node giao tiếp sẽ đóng vai trò thu thập tất cả các phản hồi từ các node chứa dữ liệu và trả về một kết quả cuối cùng cho client. Nó được thực hiện trong suốt với người dùng bởi 
Elasticsearch.

Cluster health
----

Có rất nhiều số liệu được giám sát trong một Elasticsearch cluster, nhưng có một thứ quan trọng là cluster health, nó có các trạng thái là green, yellow, red.
```sh
GET /_cluster/health
```

- green: Tất cả các primary và replica shard đều hoạt động
- yellow: Tất cả các primary shard đều hoạt động, nhưng không phải tất cả replica đều hoạt động
- red: Không phải tất cả primary shard đều hoạt động

Add an index
----

Để thêm dữ liệu vào Elasticsearch, chúng ta cần một index - chứa các dữ liệu liên quan. Index ở đây chỉ là một logical namespace trỏ tới một hoặc nhiều physical shard.

Một shard là một low-level worker unit chứa một phần của tất cả các dữ liệu trong index. Document được lưu trữ và đánh chỉ mục ở trong các shard, nhưng ứng dụng thì không trao đổi 
trực tiếp với shard, thay vào đó, chúng trao đổi với một index.

Shard là cách Elasticsearch phân chia dữ liệu trong cluster. Hãy nghĩ shard như là nơi chứa dữ liệu, document được lưu trong các shard, các shard được lưu tại node trong cluster. 
Khi cluster tăng lên hoặc co lại, Elasticsearch sẽ tự động di chuyển các shard giữa các node để đảm bảo phần còn lại của cluster luôn được cân bằng.

Một shard có thể có cả primary shard và replica shard. Mỗi document trong index đều thuộc về một primary shard, vì thế số lượng primary shard sẽ xác định độ lớn tối đa của 
dữ liệu mà index có thể lưu.

**Note**: Không hề có lý thuyết nào nói về giới hạn của dữ liệu với primary shard có thể lưu giữ, cần có sự kiểm chứng. Cấu tạo của maximum shard phụ thuộc vào trường hợp bạn sử dụng: 
phần cứng bạn có, kích cỡ và độ phức tạp của document, cách đánh chỉ mục và truy vấn, thời gian phản hồi mong đợi.

Một replica là một bản sao của primary shard. Replica được sử dụng để cung cấp một bản sao dữ liệu dự phòng trong trường hợp phần cứng lỗi hoặc phục vụ truy vấn tìm kiếm.

![read-defi-single-node-an-index](/images/read-defi-single-node-an-index.png)

A single-node cluster with an index

Add Failover
----

Khi thêm second node và một cluster, nó phải có cùng tên cluster.name với first node. Khi đó nó sẽ tự động discover và join vào cluster của first node. Nếu không thì cần kiểm tra lại 
log để tìm lỗi: có thể do multicast bị disable trong network hoặc firewall chặn kết nối. do version java và elasticsearch khác nhau.

![read-defi-two-node](/images/read-defi-two-node.png)

A two-node cluster - all primary and replica shards are allocated

Scale horizontally
----

Chuyện gì xảy ra khi tiếp tục mở rộng cluster? Nếu thêm third node thì cluster sẽ tổ chức lại như sau:

![read-defi-third-node](/images/read-defi-third-node.png)

A three-node cluster - shards have been reallocated to spread the load

Một shard ở node 1 và node 2 sẽ di chuyển sang node 3, chúng ta sẽ có 2 shard trên một node thay vì 3 shard như trước kia. Nghĩa là tài nguyên phần cứng (CPU, RAM, I/O) trên mỗi node 
được chia sẻ cho vài shard, cho phép mỗi shard hoạt động tốt hơn.

Với tổng là 6 shard (3 primary và 3 replica), index có thể mở rộng tối đa là 6 node, mỗi shard trên một node và mỗi shard có thể được truy cập với 100% tài nguyên trên node.

Then scale some more
----

Chuyện gì tiếp tục xảy ra khi mở rộng nhiều hơn 6 node?

số lượng primary shard đã được cố định khi index được tạo. Nhưng số lượng replica shard có thể thay đổi động trong live cluster, cho phép tăng hoặc giảm tùy yêu cầu.

Hình dưới mô tả lại một index có 9 shard: 3 primary và 6 replica. Điều này cho phép chúng ta mở rộng ra tới 9 node, một shard trên một node.

![read-defi-third-node-2-replica](/images/read-defi-third-node-2-replica.png)

Increasing the number_of_replicas to 2

Copy with Failure
----

Chúng ta đã nói Elasticsearch có thể đối phó với trường hợp node lỗi. Giờ chúng ta thử thực hiện điều đó, nếu ta kill first node, cluster sẽ như sau:

![read-defi-third-node-2-replica-kill-1-node](/images/read-defi-third-node-2-replica-kill-1-node.png)

Cluster after killing one node

Node bị kill là master node. Một cluster luôn phải có một master node. Việc đầu tiên xảy ra đó là việc bầu chọn một master node mới: node 2

Primary shard bị mất khi kill node 1, index sẽ không thể thực hiện đúng nếu thiếu primary shard. Nếu chúng ta kiểm tra lại cluster health tại thời điểm này, trạng thái sẽ là red.

Rất may, ta có bản sao chép của 2 primary shard bị mất trên các node khác. việc đầu tiên của master node mới thực hiện đó thăng cấp cho replicas của các shard trên node 2 và node 3 
thành primary, chuyển cluster health thành yellow. Hành động nâng cấp này được thực hiện ngay tức thì.

# Chapter 3: Data In, Data Out

Trong chương này, chúng ta xem xét các API được sử dụng để create, retrieve, update, và delete documents. Chúng ta không quan tâm tới dữ liệu bên trong document hay cách truy vấn chúng. 
Chúng ta quan tâm cách lưu trữ document tin cậy trong Elasticsearch và cách chúng trả về.

Phần này nói nhiều về JSON nên tôi chỉ note lại một vài ý cần nhớ, nếu bạn làm lập trình thì nên đọc kỹ để thao tác dữ liệu tốt hơn.

What is a Document?
----

Thông thường, chúng ta sử dụng thuật ngữ object và document giống nhau. Tuy nhiên, có một khác biệt. Một object chỉ là một JSON object - tương tự như những gì bạn đã biết về hash, 
hashmap, dictionary, hay liên kết array. Object có thể chứa các object khác. Trong Elasticsearch, thuật ngữ document có ý nghĩa cụ thể hơn. Nó chỉ tới top-level hay root object, những 
thứ được đưa vào trong JSON và lưu trữ trong Elasticsearch với một unique ID.

Document Metadata
----

Một document không chỉ chứa dữ liệu của chính nó. Nó còn có metadata - thông tin về document. Có 3 metadata được nói tới:
- index: Nơi mà document lưu trú
- type: lớp của object mà document được miêu tả
- id: định danh duy nhất của một document

_index
----

Một index như một database trong relational database; nó là nơi chúng ta lưu trữ và đánh chỉ mục dữ liệu.

**note**: trong Elasticsearch, dữ liệu được lưu trữ và đánh chỉ mục trong các shard, trong khi một index đơn giản chỉ là một logical namespace nhóm một hoặc nhiều shard lại với nhau.

index name phải là chữ thường, không được bắt đầu với gạch dưới, không được chứa dấu phẩy

_type
----



/

# Tài liệu tham khảo

Ebook:
- Elasticsearch The Definitive Guide - Clinton Gormley, Zachary Tong (2015)
