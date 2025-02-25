#!/bin/bash
proc_id=`ps -ef |grep -w docsify | grep -v grep | awk '{print $2}'`
proc_msg=`ps -ef |grep -w docsify | grep -v grep | awk '{print $8,$9,$10,$11,$12,$13}'`
if [ "$proc_id" != "" ]; then
    ps -ef |grep -w docsify | grep -v grep | awk '{print $2}' |xargs kill -9
    echo "kill ${proc_id} ${proc_msg}"
fi
nohup docsify serve /data/workspace/Docsify-Guide --port 3000 > /var/log/Docsify-Guide/docsify.log 2>&1 &
echo "server started !"

