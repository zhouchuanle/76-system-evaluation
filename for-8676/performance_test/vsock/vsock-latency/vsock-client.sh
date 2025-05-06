#!/bin/bash

if [ $# -ne 4 ]; then
    echo "Usage: $0 [-c A/Y/T/a] [-s A/Y/T/a]"
    echo "c:client s:server A/Y/T/a:Android/Yocto/Tbox/all(全部执行)"
    echo "eg: ./vsock-client.sh -c Y -s A"
    exit 1
fi

# grep -o 'max=[^,]*' L--A.log | sed 's/max=//' >> L--A.log

if [[ ($2 == "L" && $4 == "A") || ($2 == "a" && $4 == "a") ]]; then
    start_time=$(date +%s)
    while [ $(($(date +%s) - start_time)) -lt 600 ]; do
        adb -s 127.0.0.1:7665 shell "/data/vsock_mtk_ut -m client -i 0 -s 1000 -n 100000 -t 0 -p 9000 -v vsock -c 3" | tee -a L--A.log
        sleep 5
    done
fi

if [[ ($2 == "A" && $4 == "L") || ($2 == "a" && $4 == "a") ]]; then
    start_time=$(date +%s)
    while [ $(($(date +%s) - start_time)) -lt 600 ]; do
        adb -s 127.0.0.1:7666 shell "/data/vsock_mtk_ut -m client -i 0 -s 1000 -n 100000 -t 0 -p 9000 -v vsock -c 2" | tee -a A--L.log
        sleep 5
    done
fi

if [[ ($2 == "L" && $4 == "T") || ($2 == "a" && $4 == "a") ]]; then
    start_time=$(date +%s)
    while [ $(($(date +%s) - start_time)) -lt 600 ]; do
        adb -s 127.0.0.1:7665 shell "/data/vsock_mtk_ut -m client -i 0 -s 1000 -n 100000 -t 0 -p 9000 -v vsock -c 4" | tee -a L--T.log
        sleep 5
    done
fi

if [[ ($2 == "T" && $4 == "L") || ($2 == "a" && $4 == "a") ]]; then
   start_time=$(date +%s)
    while [ $(($(date +%s) - start_time)) -lt 600 ]; do
        adb -s 127.0.0.1:7667 shell "/data/vsock_mtk_ut -m client -i 0 -s 1000 -n 100000 -t 0 -p 9000 -v vsock -c 2" | tee -a T--L.log
        sleep 5
    done
fi

if [[ ($2 == "A" && $4 == "T") || ($2 == "a" && $4 == "a") ]]; then
    start_time=$(date +%s)
    while [ $(($(date +%s) - start_time)) -lt 600 ]; do
        adb -s 127.0.0.1:7666 shell "/data/vsock_mtk_ut -m client -i 0 -s 1000 -n 100000 -t 0 -p 9000 -v vsockx -c 4" | tee -a A--T.log
        sleep 5
    done
    echo "已运行12小时,测试结束。"
fi

if [[ ($2 == "T" && $4 == "A") || ($2 == "a" && $4 == "a") ]]; then
    start_time=$(date +%s)
    while [ $(($(date +%s) - start_time)) -lt 600 ]; do
        adb -s 127.0.0.1:7667 shell "/data/vsock_mtk_ut -m client -i 0 -s 1000 -n 100000 -t 0 -p 9000 -v vsockx -c 2" | tee -a T--A.log
        sleep 5
    done
    echo "已运行12小时,测试结束。"
fi
