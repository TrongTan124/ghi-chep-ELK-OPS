# 1. Logstash là gì?

Logstash là một công cụ mạnh mẽ cho việc tập trung và phân tích log, giúp cho bạn có một cái nhìn về môi trường và hoạt động của server.

# 2. Cấu hình

Kiểm tra version logstash:
```sh
# /opt/logstash/bin/logstash --version

==>
logstash 2.3.4
```

Việc cấu hình thường được thực hiện là khai báo Grok để matching dữ liệu đầu vào ở file filter. 

Có 2 phần khai báo.
	**type** được khai báo trước, nó nằm ở 
```sh
# /opt/logstash/vendor/bundle/jruby/1.9/gems/logstash-patterns-core-2.0.5/patterns
```
đối với phiên bản logstash


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

Config logstash cho network cisco
```sh
input {
        udp {
                port => 10514
                type => "cisco-fw"
        }
}

filter {

        # Extract fields from the each of the detailed message types
        # The patterns provided below are included in core of LogStash 1.4.2.
        grok {
                match => [
                        "message", "%{CISCOFW106001}",
                        "message", "%{CISCOFW106006_106007_106010}",
                        "message", "%{CISCOFW106014}",
                        "message", "%{CISCOFW106015}",
                        "message", "%{CISCOFW106021}",
                        "message", "%{CISCOFW106023}",
                        "message", "%{CISCOFW106100}",
                        "message", "%{CISCOFW110002}",
                        "message", "%{CISCOFW302010}",
                        "message", "%{CISCOFW302013_302014_302015_302016}",
                        "message", "%{CISCOFW302020_302021}",
                        "message", "%{CISCOFW305011}",
                        "message", "%{CISCOFW313001_313004_313008}",
                        "message", "%{CISCOFW313005}",
                        "message", "%{CISCOFW402117}",
                        "message", "%{CISCOFW402119}",
                        "message", "%{CISCOFW419001}",
                        "message", "%{CISCOFW419002}",
                        "message", "%{CISCOFW500004}",
                        "message", "%{CISCOFW602303_602304}",
                        "message", "%{CISCOFW710001_710002_710003_710005_710006}",
                        "message", "%{CISCOFW713172}",
                        "message", "%{CISCOFW733100}"
                ]
        }

        # Parse the syslog severity and facility
        syslog_pri { }

# Do a DNS lookup for the sending host
# Otherwise host field will contain an
# IP address instead of a hostname
dns {
    reverse => [ "host" ]
    action => "replace"
  }

geoip {
      source => "src_ip"
      target => "geoip"
      database => "/etc/logstash/GeoLiteCity.dat"
      add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
      add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}"  ]
    }
    mutate {
      convert => [ "[geoip][coordinates]", "float"]
    }
    # do GeoIP lookup for the ASN/ISP information.
    geoip {
      database => "/etc/logstash/GeoIPASNum.dat"
      source => "src_ip"
    }
}

output {
  elasticsearch { host => localhost }
}
```

# Tham khảo
- [https://www.digitalocean.com/community/tutorials/adding-logstash-filters-to-improve-centralized-logging](https://www.digitalocean.com/community/tutorials/adding-logstash-filters-to-improve-centralized-logging)
- [http://ict.renevdmark.nl/2015/10/22/cisco-asa-alerts-and-kibana/](http://ict.renevdmark.nl/2015/10/22/cisco-asa-alerts-and-kibana/)
