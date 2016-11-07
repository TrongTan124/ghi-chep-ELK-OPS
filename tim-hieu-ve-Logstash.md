# 1. Logstash là gì?

Logstash là một công cụ mạnh mẽ cho việc tập trung và phân tích log, giúp cho bạn có một cái nhìn về môi trường và hoạt động của server.

# 2. Cấu hình

Sau đây là một số bộ lọc được sử dụng tại logstash, các client cần được khai báo đúng type để logstash chọn đúng grok

```sh
filter {
  if [type] == "linuxlog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
    }
  }
  if [type] == "windowslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}?: %{POSINT:syslog_pid}?: %{GREEDYDATA:syslog_message}" }
    }
  }
  if [type] == "syslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
      add_field => [ "received_at", "%{@timestamp}" ]
      add_field => [ "received_from", "%{host}" ]
    }
    syslog_pri { }
    date {
      match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
}
```

Configuration Logstash example:
```sh
input {
  tcp {
    port => 5000
    type => windowslog
  }
  udp {
    port => 5000
    type => windowslog
  }
  tcp {
    port => 5001
    type => linuxlog
  }
  udp {
    port => 5001
    type => linuxlog
  }
}
filter {
  if [type] == "linuxlog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
    }
  }
  if [type] == "windowslog" {
    grok {
      match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}?: %{POSINT:syslog_pid}?: %{GREEDYDATA:syslog_message}" }
    }
  }
}
output {
  elasticsearch { host => localhost }
  stdout { codec => rubydebug }
}
```

Define config logstash http:
```sh
filter {
	if [type] == "http-access" {
		grok {
			match => { "message" => "%{IPORHOST:clientip} %{USER:ident} %{USER:auth} %{USER:LoadTime} [%{HTTPDATE:timestamphttp}] (?:%{WORD:verb} %{NOTSPACE:request}(?: HTTP/%{NUMBER:httpversion})?|%{DATA:rawrequest}) %{NUMBER:response} (?:%{NUMBER:bytes}|-)" }
		}
		date {
			match => [ "timestamphttp", "dd/MMM/yyyy:HH:mm:ss Z" ]
		}
	}
}

filter {
	if [type] == "http-error" {
		grok {
			match => { "message" => "[%{DAY} %{MONTH} %{MONTHDAY} %{TIME} %{YEAR}] [%{WORD:severity}] [client %{IP:clientip}] %{GREEDYDATA:message}" }
		}
	}
}
```

**Note**: check nginx not access, 502 bad gateway:
```sh
# setsebool -P httpd_can_network_connect 1
```

# Tham khảo
- [https://www.digitalocean.com/community/tutorials/adding-logstash-filters-to-improve-centralized-logging](https://www.digitalocean.com/community/tutorials/adding-logstash-filters-to-improve-centralized-logging)
