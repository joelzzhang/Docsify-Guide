#!/bin/bash
current_dir=dirname $0
echo 'current dir is '$current_dir
cd current_dir && cd ..
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
$LOG_FILE=/var/log/Docsify-Guide/git-pull.log
# 追加时间戳到日志文件
echo "=============$TIMESTAMP=============" >> "$LOG_FILE"
/bin/bash -c "git pull >> $LOG_FILE 2>&1"