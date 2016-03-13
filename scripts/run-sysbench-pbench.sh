#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

source /etc/multivm.config

export PARAMS="--test=oltp --mysql-table-engine=innodb \
              --oltp-table-size=$OLTP_TABLE_SIZE \
              --max-time=$TIME --max-requests=0 \
              --mysql-user=$MYSQL_USERNAME --mysql-password=$MYSQL_PASS run"

echo >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
echo >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
echo "sysbench test START: ------------------->" >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
date >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
uname -a >> ${RESULTS_DIR%/}/$E_LOG_FILENAME

DESCRIP=$1
clear-tools
register-tool-set
clear-results
# benchmark_run_dir=/var/lib/pbench-agent/sysbench_$DESCRIP

for i in $THREADS; do

    # Prep for pbench
    kill-tools

  ( # benchmark_results_dir=$benchmark_run_dir/$i
    # benchmark_tools_dir=$benchmark_results_dir/tools-default

    # mkdir -p $benchmark_tools_dir

    # metadata_log --dir=$benchmark_results_dir beg

    # start-tools --group=default --iteration=$i --dir=$benchmark_tools_dir

    echo $TIME
    echo $DESCRIP
    echo $THREADS
    echo $i
    printf "%3d: [%d secs] " $i $TIME
    sysbench $PARAMS --num-threads=$i |
      grep transactions: | tee -a ${RESULTS_DIR%/}/$E_LOG_FILENAME

    # stop-tools --group=default --iteration=$i --dir=$benchmark_tools_dir
    # postprocess-tools --group=default --iteration=$i --dir=$benchmark_tools_dir

    # metadata_log --dir=$benchmark_results_dir end
  )

done

echo "<------------- sysbench test END" >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
echo >> ${RESULTS_DIR%/}/$E_LOG_FILENAME

# cp -p ${RESULTS_DIR%/}/$E_LOG_FILENAME $benchmark_run_dir
