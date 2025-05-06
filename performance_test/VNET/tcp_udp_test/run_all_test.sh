#!/bin/bash

echo "脚本默认设备序列号 YOCTO_DEV="127.0.0.1:7665" ANDROID_DEV="127.0.0.1:7666" TBOX_DEV="127.0.0.1:7667" 若有变更请手动更改"
if [ $# -ne 7 ]; then
    echo "Usage: $0 [number] android对应Y/T的两路ip yocto对应A/T的两路ip tbox对应A/Y的两路ip"
    echo "./run_all_test.sh 100 172.16.16.2 193.18.8.101 172.16.16.1 172.16.17.1 193.18.8.102 172.16.17.2"
    exit 1
fi

rm -rf ./*log ./*.txt

TCP_COUNT=$1
android_y=$2
android_t=$3
yocto_a=$4
yocto_t=$5
tbox_a=$6
tbox_y=$7

YOCTO_DEV="127.0.0.1:7665"
ANDROID_DEV="127.0.0.1:7666"
TBOX_DEV="127.0.0.1:7667"

cleanup() 
{
    ./iperf3_server.sh stop
    exit 0
}
trap cleanup SIGINT

./iperf3_server.sh start

# 系统对应 IP 映射函数
map_target_ip_to_system() {
    local ip="$1"
    case "$ip" in
        $android_y|$android_t)
            echo "android"
            ;;
        $tbox_y|$tbox_a)
            echo "tbox"
            ;;
        $yocto_a|$yocto_t)
            echo "yocto"
            ;;
        *)
            echo "$ip"
            ;;
    esac
}



set_net_params() {
    local device=$1
    adb -s "$device" shell sh -c "'\
echo 8388608 > /proc/sys/net/core/rmem_default && \
echo 8388608 > /proc/sys/net/core/rmem_max && \
echo 8388608 > /proc/sys/net/core/wmem_default && \
echo 8388608 > /proc/sys/net/core/wmem_max && \
echo 0 > /proc/sys/kernel/printk && \
echo 0 > /proc/mtprintk'"
}


normal_tcp_test() {
    local device=$1
    local system=$2     
    local label=$3      
    shift 3
    for target in "$@"; do
        local mapped_name
        mapped_name=$(map_target_ip_to_system "$target")

        local log_file="/data/${system}_${mapped_name}_tcp_${label}.log"
        adb -s "$device" shell 'i=1; while [ "$i" -le '"$TCP_COUNT"' ]; do echo "Running test $i"; iperf3 --logfile '"$log_file"' -c '"$target"' -i 3 -t 15; i=$((i + 1)); done'
    done
}

normal_udp_test() {
    local device=$1
    local system=$2     
    local label=$3      
    shift 3
    for target in "$@"; do
        local mapped_name
        mapped_name=$(map_target_ip_to_system "$target")

        local log_file="/data/${system}_${mapped_name}_udp_${label}.log"
        adb -s "$device" shell 'i=1; while [ "$i" -le '"$TCP_COUNT"' ]; do echo "Running test $i"; iperf3 --logfile '"$log_file"' -c '"$target"' -i 3 -t 15 -u -b 1000m; i=$((i + 1)); done'
    done
}


run_all_tests() {
    for dev in "$YOCTO_DEV" "$ANDROID_DEV" "$TBOX_DEV"; do
        echo "设置 $dev 网络参数..."
        set_net_params $dev
        echo "删除 $dev /data 下的 *_tcp_*.log *_udp_*.log 文件..."
        adb -s "$dev" shell "rm -rf /data/*_tcp_*.log"
        adb -s "$dev" shell "rm -rf /data/*_udp_*.log"
    done

    echo -e "\n====== 普通 tcp 测试 ======"
    normal_tcp_test "$YOCTO_DEV" "yocto" "normal" $android_y $tbox_y
    normal_tcp_test "$ANDROID_DEV" "android" "normal" $yocto_a $tbox_a
    normal_tcp_test "$TBOX_DEV" "tbox" "normal" $yocto_t $android_t
    normal_udp_test "$YOCTO_DEV" "yocto" "normal" $android_y $tbox_y
    normal_udp_test "$ANDROID_DEV" "android" "normal" $yocto_a $tbox_a
    normal_udp_test "$TBOX_DEV" "tbox" "normal" $yocto_t $android_t

    echo -e "\n====== 所有 tcp 测试完成 ======"
}

run_all_tests

./iperf3_server.sh stop

# 拉取日志文件，注意文件名中包含系统标识及测试标签
adb -s $YOCTO_DEV pull /data/yocto_android_tcp_normal.log
adb -s $YOCTO_DEV pull /data/yocto_tbox_tcp_normal.log
adb -s $ANDROID_DEV pull /data/android_yocto_tcp_normal.log
adb -s $ANDROID_DEV pull /data/android_tbox_tcp_normal.log
adb -s $TBOX_DEV pull /data/tbox_android_tcp_normal.log
adb -s $TBOX_DEV pull /data/tbox_yocto_tcp_normal.log

adb -s $YOCTO_DEV pull /data/yocto_android_udp_normal.log
adb -s $YOCTO_DEV pull /data/yocto_tbox_udp_normal.log
adb -s $ANDROID_DEV pull /data/android_yocto_udp_normal.log
adb -s $ANDROID_DEV pull /data/android_tbox_udp_normal.log
adb -s $TBOX_DEV pull /data/tbox_android_udp_normal.log
adb -s $TBOX_DEV pull /data/tbox_yocto_udp_normal.log

./extract_tcp_receiver.sh