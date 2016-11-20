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

Trong application, chúng ta sử dụng object để miêu tả mọi thứ như một user, một blog post, một comment hay một email. mỗi object thuộc về một class đã định nghĩa thuộc tính cho object. 
Object trong user class có thể có tên, giới tính, tuổi, địa chỉ email.

Trong relational database chúng ta thường lưu các object của cùng class trong cùng một bảng bởi vì chúng sử dụng cấu trúc giống nhau. Tương tự, Elasticsearch sử dụng cùng type của document 
để miêu tả các thứ trong cùng class.

Mọi type đều có mapping riêng hoặc schema, thứ mà định nghĩa cấu trúc dữ liệu cho document của type đó, giống với cột trong bảng của một database. Document của tất cả các type có thể 
được lưu trữ trong cùng index, nhưng mapping của type nói với Elasticsearch cách dữ liệu trong mỗi document được đánh chỉ mục.

_Id
----

ID là một string kết hợp với index và type để định danh duy nhất một document trong Elasticsearch. Khi tạo một document mới, bạn có thể cung cấp 
id riêng hoặc Elasticsearch sinh ra một ID cho bạn.

Indexing a Document
----

Các document được đánh chỉ mục - lưu trữ và tìm kiếm - bằng cách sửa dụng index API. nhưng đầu tiên, chúng ta cần xác định nơi document lưu trú. Như đã nói, _index, _type, _id của document 
xác định duy nhất document. Chúng ta cũng có thể cung cấp _id riêng hoặc cho phép index API tự sinh ra.

**Using our own ID**

Mọi document đều có số version. mọi thay đổi tác động lên document đều làm số version tăng lên (bảo gồm cả delete). 

**autogenerating ID**

autogenerating ID dài 22 ký tự, URL-safe, base64-encoded or UUIDs.

Retrieving a Document
----

Phản hồi cho GET request bao gồm {"found": true}, xác nhận là document đã được tìm thấy.

# Chapter 4: Distributed document store

Trong chương này, chúng ta sẽ đi sâu vào các liên kết nội tại, chi tiết kỹ thuật để giúp bạn hiểu về cách dữ liệu được lưu trữ trong hệ thống phân tán.

Routing a document to a shard
----

Khi bạn đánh chỉ mục một document, nó được lưu vào primary shard. Làm thế nào mà Elasticsearch biết document thuộc về shard nào? Khi chúng ta tạo một document mới, làm cách nào mà 
Elasticsearch biết document đó nên lưu tại shard 1 hay shard 2? 

Việc xử lý không thể ngẫu nhiên, vì chúng ta còn cần truy vấn trong tương lai. Nó xác định theo một công thức đơn gian:
```sh
shard = hash(routing) % number_of_primary_shards
```

Routing có thể là một chuỗi tùy ý, mặc định là _id của document, nhưng có thể thiết lập giá trị cho nó. Chuỗi routing thông qua hàm hashing để sinh ra một số, số này được chia cho 
số primary shard trong index để thành remainder. Remainder sẽ luôn nằm trong khoảng từ 0 tới number_of_primary_shards - 1 và giúp ta xác định shard lưu trữ document.

Điều này giải thích tại sao số lượng primary shard có thể được thiết lập chỉ khi một index được tạo và không bao giờ thay đổi: nếu số lượng primary shards thay đổi trong tương lai, 
tất cả các giá trị routing trước đó sẽ mất giá trị và document không bao giờ được tìm thấy.

**Note** Có cách để thay đổi primary shard, nhưng sẽ bàn luận tại chương 43. Giá trị routing được thiết lập tùy biến để giúp người dùng lưu trữ các document liên quan nhau được 
lưu tại cùng shard.

How primary and replica shards interact
----

Để giải thích rõ ràng, chúng ta sử dụng hình dưới, một cluster có 3 node chứa 1 index là blog và có 2 primary shard. mỗi primary shard có 02 replica. Các bản sao chép giống nhau 
thì không bao giờ được đặt trên cùng node.

![read-defi-chapter4-1](/images/read-defi-chapter4-1.png)

A cluster with three nodes and one index

Chúng ta có thể gửi request tới mọi node trong cluster. Mọi node đều có khả năng nhận các request. Mọi node đều biết vị trí của mọi document trong cluster và có thể chuyển tiếp 
request tới node yêu cầu. Ví dụ gửi request tới Node 1, chúng ta quy định cho nó như một requesting node.

Creating, Indexing, and Deleting a Document
----

Các request create, index và delete là các hành động write, chúng phải được hoàn thành trên primary shard trước khi sao chép sang replica shard liên quan.

![read-defi-chapter4-2](/images/read-defi-chapter4-2.png)

Creating, indexing, and deleting a single document

Dưới đây là chuỗi các bước cần thiết để create, index, và delete document thành công trên cả primary và mọi replica shard.
1. Client gửi request create, index, delete tới Node 1
2. node sử dụng _id của document để xác định document thuộc về shard 0. Nó chuyển tiếp yêu cầu tới Node 3, nơi mà primary shard 0 được xác định.
3. Node 3 thực hiện request trên primary shard. Nếu thành công nó chuyển tiếp yêu cầu một cách song song tới replica trên node 1 và node 2. Khi tất cả các replica shard báo thành công, 
Node 3 phản hồi thành công cho requesting node để báo thành công cho client.

Khi client nhận phản hồi thành công, các thay đổi của document đã được thực thi trên tất cả primary và replica shard. Thay đổi được an toàn.

Có một số tùy chọn các tham số request cho phép bạn tác động vào quá trình xử lý trên, mục đích tăng hiệu năng và an toàn dữ liệu. Các tùy chọn này hiếm khi được sử dụng trong Elasticsearch,
bởi vì Elasticsearch rất nhanh. Nhưng chúng ta sẽ trình bày ở đây cho đầy đủ.
- replication: giá trị mặc định của replication là sync, nghĩa là primary shard đợi phản hồi thành công của tất cả replica shard trước khi trả về phản hồi. Nếu replication là async thì 
nó sẽ trả về thành công cho client ngay khi thực thi xong trên primary shard. Nó vẫn chuyển tiếp request cho replica nhưng sẽ không biết được replica có thành công hay ko.
- consistency: Mặc định, primary shard yêu cầu một quorum, hay majority của các bản sao chép shard (ở đây, shard copy có thể là primary hoặc replica shard) sẵn sàng trước khi thực hiện 
hành động write. Điều này tránh ghi dữ liệu vào "wrong side" của một network cụ thể. Quorum được tính như sau
```sh
int( (primary + number_of_replicas) / 2 ) + 1
```
- timeout: Chuyện gì xảy ra nếu không đủ shard? Elasticsearch sẽ đợi và hy vọng shard đó xuất hiện. Mặc định nó sẽ đợi 1 phút.

Retrieving a Document
----

Một document có thể được nhận từ một primary shard hoặc từ mọi replica của nó.

![read-defi-chapter4-3](/images/read-defi-chapter4-3.png)

Retrieving a single document

ở đây là chuỗi các bước để nhận một document từ cả primary và replica shard:
1. Client gửi get request tới Node 1
2. Node sử dụng _id của document để xác định, và biết document thuộc shard 0. Sao chép của shard 0 tồn tại trên cả 03 node. Tại thời điểm này, nó chuyển tiếp yêu cầu sang node 2.
3. node 2 trả về document cho node 1, node 1 sử dụng kết quả trả về cho client

Khi đọc request, requesting node sẽ chọn các bản sao chép khác nhau của shard theo thuật toán cân bằng. nó sẽ xoay vòng thông qua tất cả các bản copy shard.

Partial Updates to a Document
----

**Chưa có time **


# Chapter 5: Searching - The Basic Tools



# Tài liệu tham khảo

Ebook:
- Elasticsearch The Definitive Guide - Clinton Gormley, Zachary Tong (2015)
