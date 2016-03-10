#!/bin/bash

AIO_MODE='native'

# for i in `cat /tmp/vm_hostnames`; do
#   echo "running sysbench on: $i"
#   ssh root@$i "/root/start_sysbench_tests.sh root 90feet- $AIO_MODE"
# done


for i in `cat /tmp/vm_hostnames`; do
    echo "displaying results file on: $i"
    ssh root@$i "ls -lh /root/scripts/results /root/scripts/"
    # ssh root@$i "rm -f /root/scripts/results/*01\:01*"
done
