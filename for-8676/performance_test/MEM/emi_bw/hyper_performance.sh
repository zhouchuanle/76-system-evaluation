#!/bin/bash
adb root

adb -d forward tcp:7665 tcp:6665
adb connect 127.0.0.1:7665

adb -d forward tcp:7666 tcp:6666
adb connect 127.0.0.1:7666

adb -d forward tcp:7667 tcp:6667
adb connect 127.0.0.1:7667

adb -s 127.0.0.1:7666 root
adb -s 127.0.0.1:7667 root

yadb=127.0.0.1:7665
aadb=127.0.0.1:7666
tadb=127.0.0.1:7667

adb -s ${yadb} shell "thermal-int apply disable_thermal.conf"
adb -s ${yadb} shell "echo 3 > /sys/class/thermal/cooling_device1/cur_state"
adb -s ${yadb} shell " echo  1900000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq"
adb -s ${yadb} shell " echo  1900000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
adb -s ${yadb} shell " echo  2800000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq"
adb -s ${yadb} shell " echo  2800000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq"
adb -s ${yadb} shell " echo  2900000 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq"
adb -s ${yadb} shell " echo  2900000 > /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq"

adb -s ${yadb} shell "echo 0 > /sys/kernel/helio-dvfsrc/dvfsrc_force_vcore_dvfs_opp"
adb -s ${yadb} shell "cat /sys/bus/platform/drivers/dramc_drv/dram_data_rate"
adb -s ${yadb} shell "cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq"


adb -s ${tadb} shell " echo  1900000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq"
adb -s ${tadb} shell " echo  1900000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
adb -s ${tadb} shell " echo  2800000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq"
adb -s ${tadb} shell " echo  2800000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq"
adb -s ${tadb} shell " echo  2900000 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq"
adb -s ${tadb} shell " echo  2900000 > /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq"



adb -s ${aadb} shell "/vendor/bin/thermal_intf apply disable_throttling.conf"
adb -s ${aadb} shell " echo  1900000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq"
adb -s ${aadb} shell " echo  1900000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq"
adb -s ${aadb} shell " echo  2800000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_min_freq"
adb -s ${aadb} shell " echo  2800000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_max_freq"
adb -s ${aadb} shell " echo  2900000 > /sys/devices/system/cpu/cpufreq/policy7/scaling_min_freq"
adb -s ${aadb} shell " echo  2900000 > /sys/devices/system/cpu/cpufreq/policy7/scaling_max_freq"

adb -s ${aadb} shell "echo 0 > /proc/gpufreqv2/fix_target_opp_index"
adb -s ${aadb} shell "echo always_on > /sys/class/misc/mali0/device/power_policy"
adb -s ${aadb} shell "cat /sys/class/misc/mali0/device/power_policy"
adb -s ${aadb} shell "cat /proc/gpufreqv2/gpufreq_status"


echo --------------------- disable log ---------------------
adb -e  shell "am broadcast -a com.debug.loggerui.ADB_CMD -s ${aadb} cmd_name stop --s ${aadb} cmd_target 119 -n com.debug.loggerui/.framework.LogReceiver"
adb -s ${aadb}  shell "getprop vendor.MB.running"
adb -s ${aadb}  shell "getprop vendor.connsysfw.running"
adb -s ${aadb}  shell "getprop vendor.mtklog.netlog.Running"

echo --------------------- disable log ---------------------
adb -s ${yadb}  shell "mobile_log_d --control stop"
adb -s ${yadb}  shell "emdlogger_ctrl 7"
adb -s ${yadb}  shell "getprop mobile_log_d"

echo ----------------------journald stop -------------------------
adb -s ${yadb} shell "mount -o remount,rw /"
adb -s ${yadb} shell "systemctl stop systemd-journald.socket"
adb -s ${yadb} shell "systemctl stop systemd-journald-audit.socket"
adb -s ${yadb} shell "systemctl stop systemd-journald-dev-log.socket"
adb -s ${yadb} shell "systemctl disable systemd-journald.socket"
adb -s ${yadb} shell "systemctl stop systemd-journald"
adb -s ${yadb} shell "systemctl disable systemd-journald-audit.socket"
adb -s ${yadb} shell "systemctl disable systemd-journald-dev-log.socket"
adb -s ${yadb} shell "systemctl disable systemd-journald"

echo --------------------- set apu perf mode ---------------------
adb -s ${yadb} shell "echo 3 0 0 0 0 > /sys/module/apu_top/parameters/aputop_func_sel"
adb -s ${yadb} shell "cat /proc/gpufreqv2/gpufreq_status"

echo --------------------- set dsu ---------------------
adb -s ${yadb} shell "modprobe cpu_hwtest"
adb -s ${yadb} shell "echo 2 > /proc/cpuhvfs/cpufreq_cci_mode"
adb -s ${yadb} shell "echo 0 > /proc/cpuhvfs/cci_dvfs_enable"
adb -s ${yadb} shell "echo 0 > /proc/cpuhvfs/cci_opp_send"                                                        

# cat /sys/devices/system/cpu/sched_ctl/sched_core_pause_info 
