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

for machine in $(cat $REMOTE_HOSTS_FILE); do
    echo "..collecting results file @ /tmp/"$machine"_"$AIO_MODE"_transactions.txt"
    ssh root@$machine "grep transac ${RESULTS_DIR%/}/*MariaDB*$AIO_MODE*txt" > /tmp/"$machine"_"$AIO_MODE"_transactions.txt
done

pbench-move-results
pbench-kill-tools
pbench-clear-tools
