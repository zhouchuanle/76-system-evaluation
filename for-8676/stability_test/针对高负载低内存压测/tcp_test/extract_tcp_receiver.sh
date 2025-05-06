#!/bin/bash
 
# 遍历当前目录下的所有 .log 文件
for file in *.log; do

    echo "文件名: $file"
 
    grep "receiver" "$file" | awk '{print $7}'

    echo -e "\n\n\n\n\n"
done > extracted_receiver.txt 
 
exit 0