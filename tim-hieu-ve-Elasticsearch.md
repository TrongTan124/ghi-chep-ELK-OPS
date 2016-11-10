Kiểm tra version của Elasticsearch:
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

# 1. Indexing


# 2. Searching


# 3. Multi Tenant – Indices and Types


# 4. Distributed, Highly Available

Elasticsearch có độ sẵn sàng cao và engine tìm kiếm phân tán. Mỗi index được cắt thành shard, mỗi shard có một hoặc nhiều replica.
Mặc định, một index được tạo với 5 shard và 1 replica với mỗi shard (5/1). Có nhiều kỹ thuật có thể sử dụng, gồm 1/10 (tăng tốc độ tìm kiếm), hay 20/1 (tăng tốc độ 
đánh chỉ mục, việc tìm kiếm thực hiện trong một shard)

# Tham khảo
- [https://github.com/elastic/elasticsearch](https://github.com/elastic/elasticsearch)
- [https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [http://blog.vnlives.net/2015/11/elasticsearch-la-gi.html](http://blog.vnlives.net/2015/11/elasticsearch-la-gi.html)
