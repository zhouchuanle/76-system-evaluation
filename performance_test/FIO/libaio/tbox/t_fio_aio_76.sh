#!/bin/bash

echo "脚本默认设备序列号 TBOX_DEV="127.0.0.1:7667" 若有变更请手动更改"
if [ $# -ne 2 ]; then
    echo "Usage: $0 [s/m/b/a] [number]"
    echo "s:small core;  m:middle core ;  b:big core ;  a:all"
    echo "number:Number of executions"
    exit 1
fi

TBOX_DEV=127.0.0.1:7667

adb -s  $TBOX_DEV root
adb -s  $TBOX_DEV shell "mkdir -p /data/fio_dir"
adb -s  $TBOX_DEV push fio ../conf libaio.so libaio.so.1 /data/fio_dir/
adb -s  $TBOX_DEV shell "chmod 777 /data/fio_dir/fio"


if [[ $1 == "s" || $1 == "a" ]]; then
    for i in $(seq 1 $2); do
        adb -s  $TBOX_DEV shell "cd /data/fio_dir; LD_LIBRARY_PATH=/data/fio_dir taskset -a 1 ./fio conf/aio_randrd.fio && LD_LIBRARY_PATH=/data/fio_dir taskset -a 1 ./fio conf/aio_randwr.fio" | tee -a core2.log
    done
fi

if [[ $1 == "m" || $1 == "a" ]]; then
    for i in $(seq 1 $2); do
        adb -s  $TBOX_DEV shell "cd /data/fio_dir;LD_LIBRARY_PATH=/data/fio_dir taskset -a 10 ./fio conf/aio_randrd.fio && LD_LIBRARY_PATH=/data/fio_dir taskset -a 10 ./fio conf/aio_randwr.fio" | tee -a core4.log
    done
fi
