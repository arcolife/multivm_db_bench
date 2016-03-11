#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

[ $# = 0 ] && {
  echo "usage: ./collect_sysbench_results.sh <multivm.config path>";
  echo "example: ./collect_sysbench_results.sh multivm.config";
  exit -1;
}

source $1

if [[ ! $AIO_MODE =~ ^(native|threads)$ ]]; then
  echo "wrong aio mode supplied. choose (native|threads)";
  exit 1
fi

for i in `cat /tmp/vm_hostnames`; do
    echo "collecting results file on: $i"
    ssh root@$i "grep transac ${RESULTS_DIR%/}/*MariaDB*$AIO_MODE*txt" > /tmp/"$i"_"$AIO_MODE"_transactions.txt
done
