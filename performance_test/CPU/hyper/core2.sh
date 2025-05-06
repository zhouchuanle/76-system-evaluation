#!/bin/bash
# 启动两个程序并将输出分别重定向到日志文件
./core2-Tbox > core2-Tbox.txt 2>&1 &
./core2-Yocto > core2-Yocto.txt 2>&1 &
wait  # 等待所有后台任务完成
