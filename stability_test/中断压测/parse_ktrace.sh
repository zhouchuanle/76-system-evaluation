#!/bin/bash 

# 检查传入参数个数
if [ $# -ne 1 ]; then
    echo "Usage: $0 [path_to_parse]"
    echo "eg: ./parse_ktrace ./debug-tool/trace/parser/parse.py"
    exit 1
fi

path_to_parse=$1

for i in {1..96}
do 
    adb -s 127.0.0.1:7665 pull /data/ktrace$i.raw ./ktrace
    $path_to_parse -k ./ktrace/ktrace$i.raw -o ./log_dir/ktrace$i.log
done

for i in {1..96}
do
    mapfile -t irq_other_lines < <(awk '/NBL\.IRQ-900041984/' ./log_dir/ktrace"$i".log)

    count=0
    irq_other_index=0

    awk '/NBL\.IRQ-900000164/' ./log_dir/ktrace"$i".log | while read -r line; do
        echo "$line" | tee -a data-all.log
        ((count++))

        if (( count % 3 == 0 )); then
            if (( irq_other_index < ${#irq_other_lines[@]} )); then
                echo "${irq_other_lines[$irq_other_index]}" | sed 's/^[ \t]*//' | tee -a data-all.log
                ((irq_other_index++))
            else
                echo "done" >&2
            fi
        fi
    done
done

grep "GEN" data-all.log | awk '{print $4}' | sed 's/:$//' >> result.txt
echo "------------------------------------------------------------------------------------" >> result.txt
grep "B|99999" data-all.log | awk '{print $5}' | sed 's/:$//' >> result.txt
echo "------------------------------------------------------------------------------------" >> result.txt
grep -w "E" data-all.log | awk '{print $5}' | sed 's/:$//' >> result.txt
echo "------------------------------------------------------------------------------------" >> result.txt
grep "INJECT" data-all.log | awk '{print $5}' | sed 's/:$//' >> result.txt
