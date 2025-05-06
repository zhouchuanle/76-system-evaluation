#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 [yocto_dev]"
    echo "eg: ./watchdog.sh W8IBROG6XCX4EA59YOCTO"
    exit 1
fi

yocto_dev=$1
success_num=1
num=1

wait_for_device() {
    local tbox_retry_count=0
    local android_retry_count=0

    # 尝试连接 TBOX
    while true; do
        adb -d forward tcp:7667 tcp:6667
        adb connect 127.0.0.1:7667
        output=$(adb connect 127.0.0.1:7667)
        if echo "$output" | grep -q 'failed to connect to 127.0.0.1:7667'; then
            echo "TBOX 连接失败 ($((tbox_retry_count+1))/15)"
        else
            adb -s 127.0.0.1:7667 shell "cd /sys" &>/dev/null
            if [ $? -eq 0 ]; then
                echo "TBOX 连接成功"
                break
            fi
        fi

        adb disconnect
        sleep 5

        tbox_retry_count=$((tbox_retry_count + 1))
        if [ $tbox_retry_count -ge 15 ]; then
            echo "[错误] TBOX 连接尝试超过 15 次，准备重新触发 crash"
            return 1
        fi
    done

    # 尝试连接 Android
    while true; do
        adb -d forward tcp:7666 tcp:6666
        adb connect 127.0.0.1:7666
        output=$(adb connect 127.0.0.1:7666)
        if echo "$output" | grep -q 'failed to connect to 127.0.0.1:7666'; then
            echo "Android 连接失败 ($((android_retry_count+1))/15)"
        else
            adb -s 127.0.0.1:7666 shell "cd /sys" &>/dev/null
            if [ $? -eq 0 ]; then
                echo "Android 连接成功"
                break
            fi
        fi

        adb disconnect
        sleep 5

        android_retry_count=$((android_retry_count + 1))
        if [ $android_retry_count -ge 15 ]; then
            echo "[错误] Android 连接尝试超过 15 次，准备重新触发 crash"
            return 1
        fi
    done

    return 0
}

while true; do
    if [ $num == 100 ]; then
        break
    fi
    echo "----------------------------"
    echo "执行次数: $num"
    echo "触发 crash 中..."

    adb -s $yocto_dev shell "nblruncmd -t k crash"
    if [ $? -ne 0 ]; then
        echo "[失败] crash 命令执行失败"
        sleep 10
        continue
    fi

    if ! adb wait-for-device; then
        echo "Device unresponsive, attempting reconnection..."
        # Simultaneously attempt to connect to both devices
        if ! wait_for_device "Android" $ANDROID_PORT 6666 && \
            ! wait_for_device "TBOX" $TBOX_PORT 6667; then
            echo "[ERROR] All device connections failed, restarting test"
            continue
        fi
    fi
            
    echo "[成功] 系统重启成功！"
    echo "成功次数: $success_num"

    success_num=$((success_num + 1))
    num=$((num + 1))

    sleep 5
done
