#!/bin/bash

echo "脚本默认设备序列号 YOCTO_DEV="127.0.0.1:7665" ANDROID_DEV="127.0.0.1:7666" TBOX_DEV="127.0.0.1:7667" 若有变更请手动更改"

Android="127.0.0.1:7666"
Yocto="127.0.0.1:7665"
Tbox="127.0.0.1:7667"
cpu0="cd /data; echo 800000000 | taskset -a  1 ./dhrystone"
cpu1="cd /data; echo 800000001 | taskset -a  2 ./dhrystone"
cpu2="cd /data; echo 800000002 | taskset -a  4 ./dhrystone"
cpu3="cd /data; echo 800000003 | taskset -a  8 ./dhrystone"
cpu4="cd /data; echo 800000004 | taskset -a 10 ./dhrystone"
cpu5="cd /data; echo 800000005 | taskset -a 20 ./dhrystone"
cpu6="cd /data; echo 800000006 | taskset -a 40 ./dhrystone"
cpu7="cd /data; echo 800000007 | taskset -a 80 ./dhrystone"

adb -s $Yocto push  ./dhrystone /data/dhrystone
adb -s $Yocto shell chmod 777 /data/dhrystone
adb -s $Android push  ./dhrystone /data/dhrystone
adb -s $Android shell chmod 777 /data/dhrystone
adb -s $Tbox push  ./dhrystone /data/dhrystone
adb -s $Tbox shell chmod 777 /data/dhrystone

core0(){
adb -s $Yocto shell "$cpu0" > core0.txt 2>&1 &
}

core1(){
adb -s $Android shell "$cpu0" >core1.txt 2>&1 &
}

core2-Yocto(){
adb -s $Yocto shell "$cpu2" >core2-Yocto.txt 2>&1 
}

core2-Tbox(){
adb -s $Tbox shell "$cpu0" >core2-Tbox.txt 2>&1 
}

core2(){
    core2-Yocto &
    core2-Tbox &
    wait
}

core3(){
adb -s $Android shell "$cpu3" >core3.txt 2>&1 &
}

core4-Yocto(){
adb -s $Yocto shell "$cpu4" >core4-Yocto.txt 2>&1
}

core4-Tbox(){
adb -s $Tbox shell "$cpu4" >core4-Tbox.txt 2>&1
}

core4(){
    core4-Yocto &
    core4-Tbox &
    wait
}


core5-Yocto(){
adb -s $Yocto shell "$cpu5" >core5-Yocto.txt 2>&1
}

core5-Android(){
adb -s $Android shell "$cpu5" >core5-Android.txt 2>&1
}

core5(){
    core5-Yocto &
    core5-Android &
    wait
}

core6-Yocto(){
adb -s $Yocto shell "$cpu6" >core6-Yocto.txt 2>&1
}

core6-Android(){
adb -s $Android shell "$cpu6" >core6-Android.txt 2>&1
}

core6(){
    core6-Yocto &
    core6-Android &
    wait
}

core7(){
adb -s $Android shell "$cpu7" >core7.txt 2>&1 &
}

core8(){
    core0 &
    core1 &
    core2 &
    core3 &
    core4 &
    core5 &
    core6 &
    core7 &
}


usage() {
    echo "用法: $0 {core0|core1|core2|core3}"
    echo "示例:"
    echo "  $0 core0    # 执行 Yocto 设备任务（日志: core0.txt)"
    echo "  $0 core1    # 执行 Android 设备任务（日志: core1.txt)"
    echo "  $0 core2    # 执行 Yocto Tbox 设备任务（日志: core2-Yocto.txt core2-Tbox.txt)"
    echo "  $0 core8    # 执行 8core 并发"
    exit 1
}

main() {
    local command=$1
    case "$command" in
        core0) core0 ;;
        core1) core1 ;;
        core2) core2 ;;
        core3) core3 ;;
        core4) core4 ;;
        core5) core5 ;;
        core6) core6 ;;
        core7) core7 ;;
        core8) core8 ;;
        *)     usage ;;
    esac
    wait
}
trap 'kill $(jobs -p) 2>/dev/null' EXIT
main "$@"
