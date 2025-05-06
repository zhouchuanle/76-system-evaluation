#!/bin/bash

echo "脚本默认设备序列号 ANDROID_DEV="127.0.0.1:7666" 若有变更请手动更改"
if [ $# -ne 2 ]; then
    echo "Usage: $0 [s/m/b/a] [number]"
    echo "s:small core;  m:middle core ;  b:big core ;  a:all"
    echo "number:Number of executions"
    exit 1
fi

ANDROID_DEV="127.0.0.1:7666"

adb -s $ANDROID_DEV root
adb -s $ANDROID_DEV remount
adb -s $ANDROID_DEV shell "mkdir -p /data/fio_dir"
adb -s $ANDROID_DEV push fio libaio.so.1 ../conf /data/fio_dir
adb -s $ANDROID_DEV shell "chmod 777 /data/fio_dir/fio"

if [[ $1 == "s" || $1 == "a" ]]; then
    for i in $(seq 1 $2); do
        adb -s $ANDROID_DEV shell "cd /data/fio_dir; LD_LIBRARY_PATH=/data/fio_dir taskset -a 1 ./fio conf/psync_randrd.fio && LD_LIBRARY_PATH=/data/fio_dir taskset -a 1 ./fio conf/psync_randwr.fio" | tee -a core1.log
    done
fi

if [[ $1 == "m" || $1 == "a" ]]; then
    for i in $(seq 1 $2); do
        adb -s $ANDROID_DEV shell "cd /data/fio_dir; LD_LIBRARY_PATH=/data/fio_dir taskset -a 20 ./fio conf/psync_randrd.fio && LD_LIBRARY_PATH=/data/fio_dir taskset -a 20 ./fio conf/psync_randwr.fio" | tee -a core5.log
    done
fi

# if [[ $1 == "b" || $1 == "a" ]]; then
#     for i in $(seq 1 $2); do
#         adb -s $ANDROID_DEV shell "cd /data/fio_dir; LD_LIBRARY_PATH=/data/fio_dir taskset -a 80 ./fio conf/psync_randrd.fio && LD_LIBRARY_PATH=/data/fio_dir taskset -a 80 ./fio conf/psync_randwr.fio" | tee -a core7.log
#     done
# fi

