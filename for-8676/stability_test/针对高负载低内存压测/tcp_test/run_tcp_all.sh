#!/bin/bash

if [ $# -ne 7 ]; then
    echo "Usage: $0 [number] android对应Y/T的两路ip yocto对应A/T的两路ip tbox对应A/Y的两路ip"
    echo "./run_tcp_all.sh 100 172.16.16.2 193.18.8.101 172.16.16.1 172.16.17.1 193.18.8.102 172.16.17.2"
    exit 1
fi

rm -rf ./*log ./*.txt

# 定义 tcp 的次数
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

adb -s $ANDROID_DEV push ../stress-ng-for-android /data
adb -s $ANDROID_DEV shell "chmod +x /data/stress-ng-for-android"
adb -s $YOCTO_DEV push ../stress-ng-for-yocto /data
adb -s $YOCTO_DEV shell "chmod +x /data/stress-ng-for-yocto"
adb -s $TBOX_DEV push ../stress-ng-for-yocto /data
adb -s $TBOX_DEV shell "chmod +x /data/stress-ng-for-yocto"

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


20mem_tcp_test() {
    local device="$1"
    local system="$2"
    local label="$3"
    local stress_cmd="$4"
    shift 4
    for target in "$@"; do
        local mapped_name
        mapped_name=$(map_target_ip_to_system "$target")
        local log_file="/data/${system}_${mapped_name}_tcp_${label}.log"

        # 获取设备上的内存信息，解析 total 和 used（单位：MB）
        local mem_info
        mem_info=$(adb -s "$device" shell "free -m" | awk '/^Mem:/ {print $2, $3}')
        if [ -z "$mem_info" ]; then
            echo "获取内存信息失败，跳过 $device 对 $target 的测试"
            continue
        fi

        local total used
        read total used <<< "$mem_info"
        echo "设备 $device 内存信息:total=${total}MB, used=${used}MB"

        local ratio=$(( used * 100 / total ))
        echo "当前内存使用率为 ${ratio}%"

        if [ $ratio -ge 85 ]; then
            echo "内存使用率已达到或超过85%(${ratio}%),不执行压力测试,直接执行测试"
            adb -s "$device" shell << EOF
            cd /data
            stress_pid=\$!
            for i in \$(seq 1 "$TCP_COUNT"); do
                echo "Running test \$i"
                iperf3 --logfile "$log_file" -c "$target" -i 3 -t 15
            done
            pkill -f "$stress_cmd"
            exit
EOF
        else
            local target_used=$(( total * 85 / 100 ))
            local add=$(( target_used - used ))
            local per_worker=$(( add / 8 ))
            if [ $per_worker -lt 1 ]; then per_worker=1; fi

            echo "当前内存使用率为 ${ratio}%，需要额外加压内存：${add}MB,每个VM worker分配 ${per_worker}MB"

            adb -s "$device" shell << EOF
            cd /data
            ./"$stress_cmd" --vm 8 --vm-bytes ${per_worker}M --vm-keep &
            stress_pid=\$!
            for i in \$(seq 1 "$TCP_COUNT"); do
                echo "Running test \$i"
                iperf3 --logfile "$log_file" -c "$target" -i 3 -t 15
            done
            pkill -f "$stress_cmd"
            exit
EOF
        fi
    done
}

80cpu_loading_tcp_test() {
    local device="$1"
    local system="$2"
    local label="$3"
    local stress_cmd="$4"
    shift 4
    for target in "$@"; do
        local mapped_name
        mapped_name=$(map_target_ip_to_system "$target")
        local log_file="/data/${system}_${mapped_name}_tcp_${label}.log"
        # adb -s "$device" shell "cd /data && ./$stress_cmd -l 80 -c 8 & i=1; while [ "$i" -le '"$TCP_COUNT"' ]; do echo "Running test $i"; iperf3 --logfile '"$log_file"' -c '"$target"' -i 3 -t 15; i=$((i + 1)); done' | tee $log_file && pkill -f $stress_cmd"
        adb -s "$device" shell << EOF
            cd /data
            ./$stress_cmd -l 80 -c 8 &
            stress_pid=\$! 
            for i in \$(seq 1 "$TCP_COUNT"); do 
                echo "Running test \$i"
                iperf3 --logfile "$log_file" -c "$target" -i 3 -t 15
            done
            pkill -f "$stress_cmd"
            exit
EOF
    done
}

run_all_tests() {
    for dev in "$YOCTO_DEV" "$ANDROID_DEV" "$TBOX_DEV"; do
        echo "设置 $dev 网络参数..."
        set_net_params $dev
        echo "删除 $dev /data 下的 *_tcp_*.log 文件..."
        adb -s "$dev" shell "rm -rf /data/*_tcp_*.log"
    done

    echo -e "\n====== 普通 tcp 测试 ======"
    normal_tcp_test "$YOCTO_DEV" "yocto" "normal" $android_y $tbox_y
    normal_tcp_test "$ANDROID_DEV" "android" "normal" $yocto_a $tbox_a
    normal_tcp_test "$TBOX_DEV" "tbox" "normal" $yocto_t $android_t

    echo -e "\n====== 20% 内存压力下 ping 测试 ======"
    20mem_tcp_test "$YOCTO_DEV" yocto 20mem "stress-ng-for-yocto" $android_y $tbox_y

    20mem_tcp_test "$ANDROID_DEV" "android" 20mem "stress-ng-for-android" $yocto_a $tbox_a

    20mem_tcp_test "$TBOX_DEV" "tbox" 20mem "stress-ng-for-yocto" $yocto_t $android_t

    echo -e "\n====== CPU 压力下 ping 测试 ======"
    80cpu_loading_tcp_test "$YOCTO_DEV" yocto 80cpu "stress-ng-for-yocto" $android_y $tbox_y

    80cpu_loading_tcp_test "$ANDROID_DEV" "android" 80cpu "stress-ng-for-android" $yocto_a $tbox_a

    80cpu_loading_tcp_test "$TBOX_DEV" "tbox" 80cpu "stress-ng-for-yocto" $yocto_t $android_t

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

adb -s $YOCTO_DEV pull /data/yocto_android_tcp_20mem1.log
adb -s $YOCTO_DEV pull /data/yocto_tbox_tcp_20mem1.log
adb -s $ANDROID_DEV pull /data/android_yocto_tcp_20mem1log
adb -s $ANDROID_DEV pull /data/android_tbox_tcp_20mem1.log
adb -s $TBOX_DEV pull /data/tbox_android_tcp_20mem1.log
adb -s $TBOX_DEV pull /data/tbox_yocto_tcp_20mem1.log

adb -s $YOCTO_DEV pull /data/yocto_android_tcp_80cpu.log
adb -s $YOCTO_DEV pull /data/yocto_tbox_tcp_80cpu.log
adb -s $ANDROID_DEV pull /data/android_yocto_tcp_80cpu.log
adb -s $ANDROID_DEV pull /data/android_tbox_tcp_80cpu.log
adb -s $TBOX_DEV pull /data/tbox_android_tcp_80cpu.log
adb -s $TBOX_DEV pull /data/tbox_yocto_tcp_80cpu.log


./extract_tcp_receiver.sh