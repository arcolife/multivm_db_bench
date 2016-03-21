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
  echo "..collecting results file @ /tmp/"
  results_name=$(ssh root@$machine cat ${RESULTS_DIR%/}/sysbench_run_result_name)
  scp root@$machine:${RESULTS_DIR%/}/$results_name.txt /tmp/"$results_name"_"$OLTP_TABLE_SIZE"_"$machine".txt
  # ssh root@$machine "grep transac ${RESULTS_DIR%/}/*MariaDB*$AIO_MODE*txt" > /tmp/"$machine"_"$AIO_MODE"_transactions.txt
done
wait

pbench-move-results
pbench-kill-tools
pbench-clear-tools
