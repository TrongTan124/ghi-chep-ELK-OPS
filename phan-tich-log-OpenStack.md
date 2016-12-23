# Log Neutron trên Controller node

## Log của neutron-server

Thư mục lưu trữ log tại: `/var/log/neutron/neutron-server.log`

- Ta sử dụng grok để phân tích, thực hiện chuyển từ chuỗi text thông thường sang regular expression

- Một số mẫu sẽ sử dụng
```sh
DAYNEUTRON (?>\d\d){1,2}-(?:0?[1-9]|1[0-2])-(?:(?:0[1-9])|(?:[12][0-9])|(?:3[01])|[1-9]) (?:2[0123]|[01]?[0-9]):(?:[0-5][0-9]):(?:(?:[0-5]?[0-9]|60)(?:[:.,][0-9]+)?)
INT (?:[+-]?(?:[0-9]+))
LOGLEVEL ([A-a]lert|ALERT|[T|t]race|TRACE|[D|d]ebug|DEBUG|[N|n]otice|NOTICE|[I|i]nfo|INFO|[W|w]arn?(?:ing)?|WARN?(?:ING)?|[E|e]rr?(?:or)?|ERR?(?:OR)?|[C|c]rit?(?:ical)?|CRIT?(?:ICAL)?|[F|f]atal|FATAL|[S|s]evere|SEVERE|EMERG(?:ENCY)?|[Ee]merg(?:ency)?)
USERNAME [a-zA-Z0-9._-]+
DATA .*?
SYSLOG5424SD \[%{DATA}\]+
GREEDYDATA .*

```

Mẫu log 1
```sh

```

Mẫu log 2
```sh
2016-11-03 17:54:04.232 23331 INFO neutron.common.config [-] /usr/bin/neutron-server version 8.2.0

Khai báo thêm
SUBLOG2 (/usr/bin/neutron-server)
CONTENLOG2 %{SUBLOG2} %{GREEDYDATA}

==> NEUTRONLOG2 %{DAYNEUTRON:thoi_gian} %{INT:so_phien} %{LOGLEVEL:cap_do_canh_bao} %{USERNAME:thiet_bi_xuat_log} %{SYSLOG5424SD:so_hieu_yeu_cau} %{CONTENLOG2:du_lieu_phien_ban}
```

Mẫu log 3
```sh
2016-11-03 17:54:04.231 23331 INFO neutron.common.config [-] Logging enabled!
2016-11-03 17:54:04.253 23331 INFO neutron.manager [-] Loading core plugin: ml2
2016-11-03 17:54:04.687 23331 INFO neutron.plugins.ml2.managers [-] Configured type driver names: ['local', 'flat', 'vlan', 'gre', 'vxlan', 'geneve']
2016-11-03 17:54:04.698 23331 INFO neutron.plugins.ml2.drivers.type_flat [-] Arbitrary flat physical_network names allowed
2016-12-23 14:53:20.809 1438 INFO neutron.plugins.ml2.drivers.type_flat [-] Allowable flat physical_network names: ['external']
2016-12-23 14:53:21.277 1438 INFO neutron.plugins.ml2.drivers.type_vlan [-] Network VLAN ranges: {'external': []}
2016-12-23 14:53:21.484 1438 INFO neutron.plugins.ml2.managers [-] Loaded type driver names: ['flat', 'vlan', 'gre', 'vxlan']
2016-12-23 14:53:21.486 1438 INFO neutron.plugins.ml2.managers [-] Registered types: ['flat', 'vlan', 'gre', 'vxlan']
2016-12-23 14:53:21.515 1438 INFO neutron.plugins.ml2.managers [-] Tenant network_types: ['vlan', 'gre', 'vxlan']


Khai báo thêm
SUBLOG3 (Logging|Loading|Configured|Arbitrary|Loaded|Registered|Tenant|Initializing|Network|Allowable)
CONTENLOG3 %{SUBLOG3} %{GREEDYDATA}

==> NEUTRONLOG3 %{DAYNEUTRON:thoi_gian} %{INT:so_phien} %{LOGLEVEL:cap_do_canh_bao} %{USERNAME:thiet_bi_xuat_log} %{SYSLOG5424SD:so_hieu_yeu_cau} %{CONTENLOG3:du_lieu_config}
```

Mẫu log 4
```sh
2016-12-23 11:48:58.749 1481 INFO oslo_service.service [-] Caught SIGTERM, stopping children
2016-12-23 11:48:58.752 1481 INFO oslo_service.service [-] Waiting on 2 children to exit
2016-12-23 11:48:58.758 1481 INFO oslo_service.service [-] Child 3276 exited with status 0
2016-12-23 11:48:58.759 1481 INFO oslo_service.service [-] Child 3277 exited with status 0
2016-12-23 11:48:58.761 1481 INFO oslo_service.service [-] Wait called after thread killed. Cleaning up.
2016-12-23 11:48:58.781 1481 INFO oslo_service.service [-] Waiting on 2 children to exit
2016-12-23 11:48:58.917 1481 INFO oslo_service.service [-] Child 3282 killed by signal 15
2016-12-23 11:48:59.035 1481 INFO oslo_service.service [-] Child 3283 killed by signal 15

Khai báo thêm
SUBLOG4 (Caught|Waiting|Child|Wait)
CONTENLOG4 %{SUBLOG4} %{GREEDYDATA}

==> NEUTRONLOG3 %{DAYNEUTRON:thoi_gian} %{INT:so_phien} %{LOGLEVEL:cap_do_canh_bao} %{USERNAME:thiet_bi_xuat_log} %{SYSLOG5424SD:so_hieu_yeu_cau} %{CONTENLOG4:du_lieu_restart}
```

Mẫu log 5
```sh

```



# Tham khảo
- []()
