#!/bin/bash

echo "脚本默认设备序列号 YOCTO_DEV="127.0.0.1:7665" ANDROID_DEV="127.0.0.1:7666" 若有变更请手动更改"
if [ $# -ne 1 ]; then
    echo "Usage: $0 [number]"
    echo "eg: ./iotest.sh 3"
    exit 1
fi

count=$1
YOCTO_DEV="127.0.0.1:7665"
ANDROID_DEV="127.0.0.1:7666"

adb -s $YOCTO_DEV push ../yocto/* /data
adb -s $ANDROID_DEV push ../android/* /data

cleanup() 
{
    adb -s "$YOCTO_DEV" shell "pkill -f iotest"
    adb -s "$ANDROID_DEV" shell "pkill -f iotest"
    exit 0
}
trap cleanup SIGINT

adb -s $YOCTO_DEV shell "/data/iotest_server.bin /data/share/media/ 300"  | tee yocto_server.csv &
sleep 2 # Waiting for the server to start
for i in $(seq 1 $count); do
    adb -s $ANDROID_DEV shell "/data/iotest_client.bin /data/vendor/share/media/ 300"
done
adb -s $YOCTO_DEV shell "pkill -f iotest"

adb -s $ANDROID_DEV shell "cd /data && ./iotest_server.bin /data/vendor/share/media/ 300"  | tee android_server.csv &
sleep 2
for i in $(seq 1 $count); do
    adb -s $YOCTO_DEV shell "/data/iotest_client.bin  /data/share/media/ 300"
done
adb -s $ANDROID_DEV shell "pkill -f iotest"

for time in 50 100 150 200; do
    echo "sleep:$time----------------agv"
    grep "sleep:$time" android_server.csv | awk -F'[:,]' '{print $5}' 
done>android_server_result.txt

for time in 50 100 150 200; do
    echo "sleep:$time----------------agv"
    grep "sleep:$time" yocto_server.csv | awk -F'[:,]' '{print $5}' 
done>yocto_server_result.txt
