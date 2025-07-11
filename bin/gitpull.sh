#!/bin/bash

# 获取当前脚本所在目录
current_dir=$(dirname "$0")
#echo "Current directory: $current_dir"

# 切换到父目录（脚本所在目录的父目录）
cd "${current_dir}/.." || exit 1

# 配置日志文件路径
LOG_FILE="/var/log/Docsify-Guide/git-pull-$(date +%Y-%m-%d).log"

# 获取当前时间戳并写入日志
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "=============$TIMESTAMP=============" >> "$LOG_FILE"

# 执行 git pull 并记录输出（非阻塞方式）
# 使用 & 符号将进程放入后台运行
# 通过 $! 记录进程ID，后续可监控状态
# 2>&1 表示将错误流合并到标准输出流

/bin/bash -c "git pull >> \"$LOG_FILE\" 2>&1" &
git_pull_pid=$!

# 可选：添加超时控制（例如最多运行10分钟）
# timeout 600 -p git_pull_pid /bin/bash -c "kill -0 \$git_pull_pid" > /dev/null

# 等待所有后台任务完成（可选）
wait "$git_pull_pid"

last_month_dash=$(date -d "last month" +%Y-%m)
logfiles=$(find /var/log/Docsify-Guide -name "git-pull-$last_month_dash*.log" | sort)
if [ -n "$logfiles" ]; then
  #echo "=============$TIMESTAMP=============" >> "$LOG_FILE"
  echo "$logfiles" >> "$LOG_FILE"
  find /var/log/Docsify-Guide -name "git-pull-$last_month_dash*.log" -exec rm -f {} \;
fi

# 输出结束提示（可选）
echo "Git pull process started (PID: $git_pull_pid). Check log file: $LOG_FILE"
