#!/bin/bash

AIO_MODE=$1

for i in `cat /tmp/vm_hostnames`; do
    echo "collecting results file on: $i"
    ssh root@$i "grep transac /root/scripts/results/327*$AIO_MODE*txt" > /tmp/"$i"_"$AIO_MODE"_transactions.txt
done
