#!/bin/sh
OnLogout() {
    # Insert whatever script you need to run at logout
    /usr/local/bin/UnisonHomeSync.sh
    exit
}

echo "INFO - Watching ${HOME}" >> /var/log/org.my.log

trap 'onLogout' SIGINT SIGHUP SIGTERM

while true; do
    sleep 86400 &
    wait $!
done
