#!/bin/bash
current_dir= dirname $0
echo 'current dir is '$current_dir
cd current_dir && cd ..
/bin/bash -c "exec git pull > /var/log/Docsify-Guide/git-pull.log"
