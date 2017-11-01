#!/bin/bash

# restart logstash weekly
datenow=$(date +"%m-%d-%y %T")
logfile=/var/log/fix_logstash.log

echo $datenow >> $logfile

service logstash restart 2>&1 >>$logfile
OUT=$?

if [ $OUT -eq 0 ]; then
	echo "restart success" >>$logfile
	echo "-----------------" >>$logfile

else
	echo "restart false" >>$logfile
	echo "-----------------" >>$logfile
fi