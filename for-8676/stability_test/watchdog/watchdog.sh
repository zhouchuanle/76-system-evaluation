#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 [number] [yocto_dev]"
    echo "eg: ./watchdog.sh 100 W8IBROG6XCX4EA59YOCTO"
    exit 1
fi

yocto_dev=$2
MAX_RETRIES=15                # Maximum retry attempts
RETRY_DELAY=10                # Retry interval in seconds
TBOX_PORT=7667                # TBOX local port
ANDROID_PORT=7666             # Android local port
ADB_TIMEOUT=2                 # ADB restart wait time
MAX_ITERATIONS=$1            # Outer loop iterations
INNER_LOOP_COUNT=6            # Inner loop iterations
WDT_TEST_PATH="/sys/kernel/debug/bugfs/wdt_test"  # Watchdog test path

wait_for_device() {
    local device_name=$1
    local local_port=$2
    local remote_port=$3
    local retry_count=0

    while true; do
        echo "[${device_name}] Attempting port forwarding and connection..."
        adb -d forward tcp:${local_port} tcp:${remote_port}
        
        output=$(adb connect 127.0.0.1:${local_port} 2>&1)
        
        if echo "$output" | grep -q "failed to connect to 127.0.0.1:${local_port}"; then
            echo "${device_name} connection failed ($((retry_count+1))/${MAX_RETRIES})"
        else

            if adb -s 127.0.0.1:${local_port} shell "cd /sys" &>/dev/null; then
                echo "${device_name} connection successful"
                return 0
            fi
        fi

        adb disconnect 127.0.0.1:${local_port} &>/dev/null
        sleep $RETRY_DELAY

        ((retry_count++))
        if [ $retry_count -ge $MAX_RETRIES ]; then
            echo "[ERROR] ${device_name} connection attempts exceeded ${MAX_RETRIES}, restarting adb service..."
            adb kill-server &>/dev/null
            adb start-server &>/dev/null
            sleep $ADB_TIMEOUT
            return 1
        fi
    done
}

main_test() {
    for i in $(seq 1 $MAX_ITERATIONS); do
        local num=$INNER_LOOP_COUNT
        
        for j in $(seq 1 $INNER_LOOP_COUNT); do

            echo "设置 watchdog test case_id: $num"
            adb -s $yocto_dev shell "echo $num > $WDT_TEST_PATH"
            
            echo "等待设备连接..."
            if ! adb wait-for-device; then
                echo "Device unresponsive, attempting reconnection..."

                if ! wait_for_device "Android" $ANDROID_PORT 6666 && \
                   ! wait_for_device "TBOX" $TBOX_PORT 6667; then
                    echo "[ERROR] All device connections failed, restarting test"
                    continue
                fi
            fi
            sleep 2

            echo "验证设备连接状态..."
            if adb -s $yocto_dev shell "cd /sys" &>/dev/null; then
                echo "Device status normal"
                echo "Successfully executed case: $num"
                ((num--))
            else
                echo "[ERROR] Device status abnormal, restarting case"
                continue
            fi
        done
        
        echo "完成循环次数: $i/$MAX_ITERATIONS"
    done

    echo "Setting final watchdog value: 6"
    adb -s $yocto_dev shell "echo 6 > $WDT_TEST_PATH"
}

main_test
