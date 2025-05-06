#!/bin/bash

if [ $# -ne 3 ]; then
    echo "Usage: $0 [s/m/b/a] [number] [yocto_dev]"
    echo "s:small core;  m:middle core;  a:all_core  yocto_dev:yocto设备序列号"
    echo "number:Number of executions"
    exit 1
fi

yocto_dev=$3

adb -s  $yocto_dev root
adb -s  $yocto_dev shell "mkdir -p /data/fio_dir"
adb -s  $yocto_dev push fio ../conf libaio.so /data/fio_dir/
adb -s  $yocto_dev shell "chmod 777 /data/fio_dir/fio"


if [[ $1 == "s" || $1 == "a" ]]; then
    for i in $(seq 1 $2); do
        adb -s  $yocto_dev shell "cd /data/fio_dir; LD_LIBRARY_PATH=/data/fio_dir taskset -a 4 ./fio conf/aio_randrd.fio && LD_LIBRARY_PATH=/data/fio_dir taskset -a 4 ./fio conf/aio_randwr.fio" | tee -a core2.log
    done
fi

if [[ $1 == "m" || $1 == "a" ]]; then
    for i in $(seq 1 $2); do
        adb -s  $yocto_dev shell "cd /data/fio_dir;LD_LIBRARY_PATH=/data/fio_dir taskset -a 10 ./fio conf/aio_randrd.fio && LD_LIBRARY_PATH=/data/fio_dir taskset -a 10 ./fio conf/aio_randwr.fio" | tee -a core4.log
    done
fi