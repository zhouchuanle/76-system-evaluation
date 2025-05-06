
#!/bin/bash

# 遍历当前目录下的所有 .log 文件
for file in *.log; do
    # 打印文件名
    echo "文件名: $file"
    # 使用 sed 提取每行中 time= 后面的数据
    sed -n 's/.*time=\([0-9.]\+\) ms.*/\1/p' "$file"
    # 输出五个换行符
    echo -e "\n\n\n\n\n"
done


# ./extract_ping_times.sh > extracted_times.txt
