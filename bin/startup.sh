#!/bin/bash
proc_id=`ps -ef |grep -w docsify | grep -v grep | awk '{print $2}'`
proc_msg=`ps -ef |grep -w docsify | grep -v grep | awk '{print $8,$9,$10,$11,$12,$13}'`
if [ "$proc_id" != "" ]; then
    ps -ef |grep -w docsify | grep -v grep | awk '{print $2}' |xargs kill -9
    echo "kill ${proc_id} ${proc_msg}"
fi
nohup docsify serve ./docs/ --port 3000 > docsify.log &
#nohup docsify serve ./docs/ --port 3000 >/dev/null 2>&1 &
echo "server started !"

