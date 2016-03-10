#!/bin/bash

AIO_MODE='native'
OLTP_TABLE_SIZE=1000000

for i in `cat /tmp/vm_hostnames`; do
  echo "running sysbench on: $i"
  ssh root@$i "/root/start_sysbench_tests.sh root 90feet- $AIO_MODE $OLTP_TABLE_SIZE"
done

for i in `cat /tmp/vm_hostnames`; do
    echo "displaying results file on: $i"
    ssh root@$i "ls -lh /root/scripts/results /root/scripts/"
done
