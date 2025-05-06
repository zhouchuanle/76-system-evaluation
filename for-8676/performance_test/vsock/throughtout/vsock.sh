# #！bin/bash

adb -s 127.0.0.1:7666 push /home/zcl/系统评测/test_tools/to_GRV_vsock_test_tool_v1129/iperf3-vsockx /data
adb -s 127.0.0.1:7665 push /home/zcl/系统评测/test_tools/to_GRV_vsock_test_tool_v1129/iperf3-vsockx /data
adb -s 127.0.0.1:7667 push /home/zcl/系统评测/test_tools/to_GRV_vsock_test_tool_v1129/iperf3-vsockx /data
adb -s 127.0.0.1:7666 push /home/zcl/系统评测/test_tools/to_GRV_vsock_test_tool_v1129/vsock_mtk_ut /data
adb -s 127.0.0.1:7665 push /home/zcl/系统评测/test_tools/to_GRV_vsock_test_tool_v1129/vsock_mtk_ut /data
adb -s 127.0.0.1:7667 push /home/zcl/系统评测/test_tools/to_GRV_vsock_test_tool_v1129/vsock_mtk_ut /data

# A<-->L 
/data/iperf3-vsockx --vsock -s -i 1
i=1; while [ $i -le 10 ]; do echo "Running test $i";/data/iperf3-vsockx --vsock -c 2 --logfile /data/A-L.log ; i=$((i + 1)); done
i=1; while [ $i -le 10 ]; do echo "Running test $i";/data/iperf3-vsockx --vsock -c 3 --logfile /data/L-A.log ; i=$((i + 1)); done

# L<-->T
/data/iperf3-vsockx --vsock -s -i 1
i=1; while [ $i -le 10 ]; do echo "Running test $i";/data/iperf3-vsockx --vsock -c 4 --logfile /data/L-T.log ; i=$((i + 1)); done
i=1; while [ $i -le 10 ]; do echo "Running test $i";/data/iperf3-vsockx --vsock -c 2 --logfile /data/T-L.log ; i=$((i + 1)); done

# A<-->T
/data/iperf3-vsockx --vsockx -s -i 1
i=1; while [ $i -le 10 ]; do echo "Running test $i";/data/iperf3-vsockx --vsockx -c 2 --logfile /data/T-A.log ; i=$((i + 1)); done
i=1; while [ $i -le 10 ]; do echo "Running test $i";/data/iperf3-vsockx --vsockx -c 4 --logfile /data/A-T.log ; i=$((i + 1)); done

grep -E "receiver" .log | awk '{print $7}'
