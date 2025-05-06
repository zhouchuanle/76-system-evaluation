#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 [file_name]"
    echo "eg: ./fio.sh core0.log"
    exit 1
fi

file_name=$1
echo -e "read\twrite\tread_delay\twrite_delay" >> result.txt

# 提取 read 和 write 的数据
read_data=$(cat "$1" | grep -E "read: IOPS" -n | awk -F"," '{print $2}' | awk -F" " '{print $1}' | awk -F"=" '{print $2}' | sed 's/MiB\/s//')
write_data=$(cat "$1" | grep -E "write: IOPS" -n | awk -F"," '{print $2}' | awk -F" " '{print $1}' | awk -F"=" '{print $2}' | sed 's/MiB\/s//')
delay_data=$(cat "$1" | grep -E "\<lat \(usec\):" -n | awk -F"," '{print $3}' | awk -F"=" '{print $2}')


# 通过 paste 命令将 read、write 和 delay 数据并排输出
paste <(echo "$read_data") <(echo "$write_data") <(echo "$delay_data" | sed -n 'p;n') <(echo "") <(echo "$delay_data" | sed -n 'n;p') >> result.txt


# cat "$1" | grep -E "read: IOPS" -n | awk -F"," '{print $2}' | awk -F" " '{print $1}' | awk -F"=" '{print $2}' | sed 's/MiB\/s//'
# cat "$1" | grep -E "write: IOPS" -n | awk -F"," '{print $2}' | awk -F" " '{print $1}' | awk -F"=" '{print $2}' | sed 's/MiB\/s//'
# cat "$1" | grep -E "\<lat \(usec\):" -n | awk -F"," '{print $3}' | awk -F"=" '{print $2}'
