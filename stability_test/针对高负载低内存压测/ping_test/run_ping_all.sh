#!/bin/bash

if [ $# -ne 7 ]; then
    echo "Usage: $0 [number] android对应Y/T的两路ip yocto对应A/T的两路ip tbox对应A/Y的两路ip"
    echo "./run_ping_all.sh 100 172.16.16.2 193.18.8.101 172.16.16.1 172.16.17.1 193.18.8.102 172.16.17.2"
    exit 1
fi

rm -rf ./*log ./*.txt

PING_COUNT=$1
android_y=$2
android_t=$3
yocto_a=$4
yocto_t=$5
tbox_a=$6
tbox_y=$7

YOCTO_DEV="127.0.0.1:7665"
ANDROID_DEV="127.0.0.1:7666"
TBOX_DEV="127.0.0.1:7667"

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

adb -s $ANDROID_DEV push ../stress-ng-for-android /data
adb -s $ANDROID_DEV shell "chmod +x /data/stress-ng-for-android"
adb -s $YOCTO_DEV push ../stress-ng-for-yocto /data
adb -s $YOCTO_DEV shell "chmod +x /data/stress-ng-for-yocto"
adb -s $TBOX_DEV push ../stress-ng-for-yocto /data
adb -s $TBOX_DEV shell "chmod +x /data/stress-ng-for-yocto"

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

stop_stress() {
    local device=$1
    local stress_tool=$2
    adb -s "$device" shell "pkill -f $stress_tool"
}

normal_ping_test() {
    local device=$1
    local system=$2      # System identifiers, such as yocto, android, tbox
    local label=$3       # Test labels, such as normal, 20mem, 80cpu
    shift 3
    for target in "$@"; do
        local mapped_name
        mapped_name=$(map_target_ip_to_system "$target")
        local log_file="/data/${system}_${label}_ping_${mapped_name}.log"
        adb -s "$device" shell "ping -c $PING_COUNT $target | tee $log_file"
    done
}

20mem_ping_test() {
    local device="$1"
    local system="$2"
    local label="$3"
    local stress_cmd="$4"
    shift 4
    for target in "$@"; do
        local mapped_name
        mapped_name=$(map_target_ip_to_system "$target")
        local log_file="/data/${system}_${label}_ping_${mapped_name}.log"

        # Get memory information on the device，Parse total and used (unit: MB)
        local mem_info
        mem_info=$(adb -s "$device" shell "free -m" | awk '/^Mem:/ {print $2, $3}')
        if [ -z "$mem_info" ]; then
            echo "Failed to obtain memory information. Skip the $device to $target test. "
            continue
        fi

        local total used
        read total used <<< "$mem_info"
        echo "设备 $device 内存信息：total=${total}MB, used=${used}MB"

        local ratio=$(( used * 100 / total ))
        echo "当前内存使用率为 ${ratio}%"
        
        if [ $ratio -ge 85 ]; then
            echo "内存使用率已达到或超过85%（${ratio}%），不执行压力测试，直接执行ping测试"
            adb -s "$device" shell "ping -c $PING_COUNT $target | tee $log_file"
        else
            local target_used=$(( total * 85 / 100 ))
            local add=$(( target_used - used ))
            local per_worker=$(( add / 8 ))
            if [ $per_worker -lt 1 ]; then per_worker=1; fi

            echo "当前内存使用率为 ${ratio}%，需要额外加压内存：${add}MB，每个VM worker分配 ${per_worker}MB"

            adb -s "$device" shell "cd /data && \
              ./$stress_cmd --vm 8 --vm-bytes ${per_worker}M --vm-keep & \
              ping -c $PING_COUNT $target | tee $log_file; \
              pkill -f $stress_cmd"
        fi
    done
}

80cpu_ping_test() {
    local device="$1"
    local system="$2"
    local label="$3"
    local stress_cmd="$4"
    shift 4
    for target in "$@"; do
        local mapped_name
        mapped_name=$(map_target_ip_to_system "$target")
        local log_file="/data/${system}_${label}_ping_${mapped_name}.log"
        adb -s "$device" shell "cd /data && ./$stress_cmd -l 80 -c 8 & ping -c $PING_COUNT $target | tee $log_file && pkill -f $stress_cmd"
    done
}

run_all_tests() {
    for dev in "$YOCTO_DEV" "$ANDROID_DEV" "$TBOX_DEV"; do
        echo "设置 $dev 网络参数..."
        set_net_params $dev
        echo "删除 $dev /data 下的 *_ping_*.log 文件..."
        adb -s "$dev" shell "rm -rf /data/*_ping_*.log"
    done

    echo -e "\n====== 普通 ping 测试 ======"
    normal_ping_test "$YOCTO_DEV" "yocto" "normal" $android_y $tbox_y
    normal_ping_test "$ANDROID_DEV" "android" "normal" $yocto_a $tbox_a
    normal_ping_test "$TBOX_DEV" "tbox" "normal" $yocto_t $android_t

    echo -e "\n====== 20% 内存压力下 ping 测试 ======"
    20mem_ping_test "$YOCTO_DEV" yocto 20mem "stress-ng-for-yocto" $android_y $tbox_y
    stop_stress "$YOCTO_DEV" "stress-ng-for-yocto"

    20mem_ping_test "$ANDROID_DEV" "android" 20mem "stress-ng-for-android" $yocto_a $tbox_a
    stop_stress "$ANDROID_DEV" "stress-ng-for-android"

    20mem_ping_test "$TBOX_DEV" "tbox" 20mem "stress-ng-for-yocto" $yocto_t $android_t
    stop_stress "$TBOX_DEV" "stress-ng-for-yocto"

    echo -e "\n====== CPU 压力下 ping 测试 ======"
    80cpu_ping_test "$YOCTO_DEV" yocto 80cpu "stress-ng-for-yocto" $android_y $tbox_y
    stop_stress "$YOCTO_DEV" "stress-ng-for-yocto"

    80cpu_ping_test "$ANDROID_DEV" "android" 80cpu "stress-ng-for-android" $yocto_a $tbox_a
    stop_stress "$ANDROID_DEV" "stress-ng-for-android"

    80cpu_ping_test "$TBOX_DEV" "tbox" 80cpu "stress-ng-for-yocto" $yocto_t $android_t
    stop_stress "$TBOX_DEV" "stress-ng-for-yocto"

    echo -e "\n====== 所有 ping 测试完成 ======"
}

run_all_tests

# 拉取日志文件，注意文件名中包含系统标识及测试标签
adb -s $YOCTO_DEV pull /data/yocto_normal_ping_android.log
adb -s $YOCTO_DEV pull /data/yocto_normal_ping_tbox.log
adb -s $ANDROID_DEV pull /data/android_normal_ping_yocto.log
adb -s $ANDROID_DEV pull /data/android_normal_ping_tbox.log
adb -s $TBOX_DEV pull /data/tbox_normal_ping_android.log
adb -s $TBOX_DEV pull /data/tbox_normal_ping_yocto.log
adb -s $YOCTO_DEV pull /data/yocto_20mem_ping_android.log
adb -s $YOCTO_DEV pull /data/yocto_20mem_ping_tbox.log
adb -s $ANDROID_DEV pull /data/android_20mem_ping_yocto.log
adb -s $ANDROID_DEV pull /data/android_20mem_ping_tbox.log
adb -s $TBOX_DEV pull /data/tbox_20mem_ping_android.log
adb -s $TBOX_DEV pull /data/tbox_20mem_ping_yocto.log
adb -s $YOCTO_DEV pull /data/yocto_80cpu_ping_android.log
adb -s $YOCTO_DEV pull /data/yocto_80cpu_ping_tbox.log
adb -s $ANDROID_DEV pull /data/android_80cpu_ping_yocto.log
adb -s $ANDROID_DEV pull /data/android_80cpu_ping_tbox.log
adb -s $TBOX_DEV pull /data/tbox_80cpu_ping_android.log
adb -s $TBOX_DEV pull /data/tbox_80cpu_ping_yocto.log

./extract_ping_times.sh > extracted_times.txt
