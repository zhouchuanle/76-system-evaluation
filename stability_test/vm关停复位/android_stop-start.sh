#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 [number] [yocto_dev]"
    echo "eg: ./android_stop_start.sh 1000 W8IBROG6XCX4EA59YOCTO"
    exit 1
fi

num=$1
yocto_dev=$2
success_num=0
failed_num=0

handle_failure() {
    failed_num=$((failed_num + 1))
    echo "$1 ------------- Failed: $failed_num"
}

wait_for_device() {
    while true; do
        state=$( adb -s $yocto_dev shell "nbl_vm_ctl vminfo" | grep -o '"vmid":"0","state":"[^"]*' | awk -F':' '{print $NF}' | tr -d '"' )
        if [ "$state" == "Started" ]; then
            echo "android Start success"
            break
        elif [ "$state" == "Stopped" ]; then
            sleep 5
        fi
    done
}

for i in $(seq 1 $num) 
do
    echo "Execution count: $i"

    adb -s $yocto_dev shell "nbl_vm_ctl stop --vmid 0"
    sleep 1
    state=$( adb -s $yocto_dev shell "nbl_vm_ctl vminfo" | grep -o '"vmid":"0","state":"[^"]*' | awk -F':' '{print $NF}' | tr -d '"' )
    if [ "$state" == "Started" ]; then
        handle_failure "android not stopped"
        continue
    elif [ "$state" == "Stopped" ]; then
        echo "android stopped"
    fi

    adb -s $yocto_dev shell "nbl_vm_ctl start --vmid 0"
    sleep 30
    wait_for_device

    success_num=$((success_num + 1))
    echo "Success count: $success_num"
    sleep 1
done
