#!/bin/bash

echo "脚本默认设备序列号 YOCTO_DEV="127.0.0.1:7665" ANDROID_DEV="127.0.0.1:7666" TBOX_DEV="127.0.0.1:7667" 若有变更请手动更改"
if [ $# -ne 4 ]; then
    echo "Usage: $0 [-s A/Y/T/a] [-n number]"
    echo "A/Y/T/a: Android/Yocto/Tbox/all number: Number of executions"
    echo "eg: ./mem_test.sh -s a -n 3"
    exit 1
fi

YOCTO_DEV="127.0.0.1:7665"
ANDROID_DEV="127.0.0.1:7666"
TBOX_DEV="127.0.0.1:7667"

adb -s $YOCTO_DEV push stream /data
adb -s $ANDROID_DEV push stream /data
adb -s $TBOX_DEV push stream /data

if [ $1 == "-s" ];then
	sys=$2
fi

if [ $3 == "-n" ];then
	num=$4
fi

if [[ $sys == "A" || $sys == "a" ]]; then
    for i in $(seq 1 $num); do
        adb -s $ANDROID_DEV shell "/data/stream -v 2 -M 64M -P 4" |tee -a  Android_stream.txt
    done
fi

if [[ $sys == "Y" || $sys == "a" ]]; then
    for i in $(seq 1 $num); do
        adb -s $YOCTO_DEV shell "/data/stream -v 2 -M 64M -P 4" |tee -a  Yocto_stream.txt
    done
fi

if [[ $sys == "T" || $sys == "a" ]]; then
    for i in $(seq 1 $num); do
        adb -s $TBOX_DEV shell "/data/stream -v 2 -M 64M -P 2" |tee -a  Tbox_stream.txt
    done
fi

