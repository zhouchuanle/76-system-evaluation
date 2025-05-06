#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 [status]"
    echo "./iperf3_server.sh start/stop"
    exit 1
fi

YOCTO_DEV="127.0.0.1:7665"
ANDROID_DEV="127.0.0.1:7666"
TBOX_DEV="127.0.0.1:7667"

if [[ $1 == "start" ]]; then
    adb -s $YOCTO_DEV shell "iperf3 -s" &
    adb -s $ANDROID_DEV shell "iperf3 -s" &
    adb -s $TBOX_DEV shell "iperf3 -s" &
fi

if [[ $1 == "stop" ]]; then
    adb -s $YOCTO_DEV shell "pkill -f iperf3"
    adb -s $ANDROID_DEV shell "pkill -f iperf3"
    adb -s $TBOX_DEV shell "pkill -f iperf3"
fi
