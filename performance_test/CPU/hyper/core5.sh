#!/bin/bash
# 启动两个程序并将输出分别重定向到日志文件
./core5-Android > core5-Android.txt 2>&1 &
./core5-Yocto > core5-Yocto.txt 2>&1 &
wait  # 等待所有后台任务完成
