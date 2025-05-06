#!/bin/bash
# 启动两个程序并将输出分别重定向到日志文件
./core4-Tbox > core4-Tbox.txt 2>&1 &
./core4-Yocto > core4-Yocto.txt 2>&1 &
wait  # 等待所有后台任务完成
