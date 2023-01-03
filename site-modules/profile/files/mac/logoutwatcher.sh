#!/usr/bin/env bash

LOG=${HOME}/Library/Log/logout.log
exec 2>&1 >> ${LOG}

onLogout() {
    # Insert whatever script you need to run at logout
    date
    /Users/gary/bin/vm_auto stop 2>&1 
    exit
}

echo "INFO - Watching ${HOME}" >> ${LOG}

trap 'onLogout' SIGINT SIGHUP SIGTERM

while true; do
    sleep 86400 &
    wait $!
done
