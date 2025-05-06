#!/bin/bash 

start_time=$(date +%s)
end_time=$(date +%s)

echo irq > /sys/kernel/debug/nebula_trace/ktrace/set_event
nblruncmd -t k irq_gen 164 3456000 50
num=1

while true; do
	if [ $(($(date +%s) - end_time)) -gt 3456000 ]; then
		break		
	fi

	# 间隔半小时抓取一次trace
	if [ $(($(date +%s) - start_time)) -gt 1800 ]; then
        
        echo 1 > /sys/kernel/debug/nebula_trace/ktrace/enable
        sleep 1	# 间隔50ms发送一次中断，抓一秒即可
        echo 0 > /sys/kernel/debug/nebula_trace/ktrace/enable

        mv /data/ktrace.raw /data/ktrace$num.raw
		num=$((num + 1))
		start_time=$(date +%s)
	fi
done
