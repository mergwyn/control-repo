#!/usr/bin/env bash

LOG=${HOME}/Library/Log/logout.log

onLogout() {
    # Insert whatever script you need to run at logout

    /Users/gary/bin/vm_auto stop 2>&1 | tee ${LOG}
    exit
}

echo "INFO - Watching ${HOME}" >> ${LOG}

trap 'onLogout' SIGINT SIGHUP SIGTERM

while true; do
    sleep 86400 &
    wait $!
done
