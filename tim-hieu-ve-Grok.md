# 1. Grok là gì?

Grok là một dạng biểu thức regular expression, được sử dụng để phân tích cấu trúc văn bản. 

# 2. Cách sử dụng

Grok được áp dụng khá đa dạng. Mỗi kiểu dữ liệu sẽ được khai báo các mẫu pattern, và có thể sử dụng lẫn nhau trong bộ lọc filter. 

Nghĩa là khi định nghĩa pattern cho kiểu log syslog, nhưng có thể sử dụng được đoạn khai báo pattern đó cho kiểu log MySQL.

# 3. Cấu hình
trên ubuntu 14.04 cài đặt theo script, thư mục chứa các khai báo pattern có sẵn hoặc tự định nghĩa tại:
```sh.*
# /opt/logstash/vendor/bundle/jruby/1.9/gems/logstash-patterns-core-2.0.5/patterns
```

Áp dụng Grok cho log Neutron. 
- Log:
```sh
2016-11-10 09:59:36.226 1453 WARNING neutron.db.agents_db [req-9ce6b266-6465-43c1-9523-f7ab30cdc3f7 - - - - -] Agent healthcheck: found 1 dead agents out of 5:
```
- Grok:
```sh
DAYNEUTRON (?>\d\d){1,2}-(?:0?[1-9]|1[0-2])-(?:(?:0[1-9])|(?:[12][0-9])|(?:3[01])|[1-9]) (?:2[0123]|[01]?[0-9]):(?:[0-5][0-9]):(?:(?:[0-5]?[0-9]|60)(?:[:.,][0-9]+)?)
AGENTLOG %{DAYNEUTRON:time_request} %{INT:session} %{LOGLEVEL:level_log} %{USERNAME:src_driver} %{SYSLOG5424SD:request_id} %{GREEDYDATA:content_log}
```
- Khai báo filter:
```sh
filter {
  if [type] == "neutron" {
    grok {
      match => { "message" => "%{AGENTLOG}" }
    } 
  }
}
```

# Tham khảo
- [https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html](https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html)
- [https://github.com/logstash-plugins/logstash-patterns-core/blob/master/patterns/grok-patterns](https://github.com/logstash-plugins/logstash-patterns-core/blob/master/patterns/grok-patterns)
- [https://github.com/logstash-plugins/logstash-patterns-core/tree/master/patterns](https://github.com/logstash-plugins/logstash-patterns-core/tree/master/patterns)
- [https://grokdebug.herokuapp.com/](https://grokdebug.herokuapp.com/)
- [https://regex101.com/](https://regex101.com/)
- [https://github.com/TrongTan124/oniguruma/blob/master/doc/RE](https://github.com/TrongTan124/oniguruma/blob/master/doc/RE)
