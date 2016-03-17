#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

RESULTS_NAME=$(cat ${RESULTS_DIR%/}/sysbench_run_result_name)
echo 2 > /proc/sys/vm/drop_caches

thread_count=$1
export PARAMS="--test=oltp --mysql-table-engine=innodb \
              --oltp-table-size=$OLTP_TABLE_SIZE \
              --max-time=$TIME --max-requests=0 \
              --mysql-user=$MYSQL_USERNAME --mysql-password=$MYSQL_PASS run"

( printf "%3d: [%d secs] " $thread_count $TIME
sysbench $PARAMS --num-threads=$thread_count |
grep transactions: | tee -a ${RESULTS_DIR%/}/$E_LOG_FILENAME
) >> ${RESULTS_DIR%/}/$RESULTS_NAME.txt
