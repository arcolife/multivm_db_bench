#!/bin/bash

AIO_MODE=$1

if [[ ! $AIO_MODE =~ ^(native|threads)$ ]]; then
  echo "wrong aio mode supplied. choose (native|threads)";
  exit 1
fi

for i in `cat /tmp/vm_hostnames`; do
    echo "collecting results file on: $i"
    ssh root@$i "grep transac /root/scripts/results/327*$AIO_MODE*txt" > /tmp/"$i"_"$AIO_MODE"_transactions.txt
done
