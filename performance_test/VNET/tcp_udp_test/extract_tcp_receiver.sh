#!/bin/bash
 
# 遍历当前目录下的所有 .log 文件
for file in *_tcp*.log; do

    echo "文件名: $file"
 
    grep "receiver" "$file" | awk '{print $7}'

    echo -e "\n\n\n\n\n"
done > tcp_receiver.txt 

for file in *_udp*.log; do

    echo "文件名: $file"
 
    grep -E "receiver" "$file" | awk '{gsub(/[()%]/, "", $12); print $12}'

    echo -e "\n\n\n\n\n"
done > udp_lost.txt

for file in *_udp*.log; do

    echo "文件名: $file"
 
    grep "receiver" "$file" | awk '{print $7}'

    echo -e "\n\n\n\n\n"
done > udp_receiver.txt 

for file in *_udp*.log; do

    echo "文件名: $file"
 
    grep "sender" "$file" | awk '{print $7}'

    echo -e "\n\n\n\n\n"
done > udp_sender.txt 
 
exit 0