#!/bin/bash

set -e

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    pbench-kill-tools
    # pbench-clear-results
    exit 1
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

# path to 'multiclient.config' and file containing hostnames
MULTICLIENT_CONFIG_FILE=multiclient.config
REMOTE_HOSTS_FILE=client_hostnames.txt

source $MULTICLIENT_CONFIG_FILE

echo "....Using client list from ./$REMOTE_HOSTS_FILE"
echo "....Using config from $MULTICLIENT_CONFIG_FILE"
echo "....parsing config from $MULTICLIENT_CONFIG_FILE"

if [[ ! $(basename $MULTICLIENT_CONFIG_FILE) =~ ^multiclient\.config$ ]]; then
    echo "need multiclient.config as 1st argument!" > sysbench.$AIO_MODE.log
    echo "ERROR. check log file - sysbench.$AIO_MODE.log"
    exit -1
fi

if [[ ! -f $MULTICLIENT_CONFIG_FILE ]]; then
    echo "config file doesn't exist!" > sysbench.$AIO_MODE.log
    echo "ERROR. check log file - sysbench.$AIO_MODE.log"
    exit -1
fi

if [[ $(pgrep automate_sysben | wc -l) -gt 2 ]]; then
  echo "more than 1 automate_sysbench scripts are currently running. Killing all." > sysbench.$AIO_MODE.log
  echo "Committing suicide. Run me again to achieve nirvana!" >> sysbench.$AIO_MODE.log
  pgrep automate_sysben | xargs kill -9
  echo "ERROR. check log file - sysbench.$AIO_MODE.log"
  exit -1
fi

echo > sysbench.$AIO_MODE.log

##############################################
if [[ ! -f sysbench-0.4.12.tar.gz ]]; then
    wget $DOWNLOAD_LINK
fi

if [[ ! -s $REMOTE_HOSTS_FILE ]]; then
    echo "..$REMOTE_HOSTS_FILE was found to be empty after trying to store IPs of supplied (running) clients !"
    exit 1
fi

echo
for machine in $(cat $REMOTE_HOSTS_FILE); do
    echo "....attempting to kill sysbench related pids, clear cache & set up bench scripts on: $machine"
    ssh $CLIENT_LOGIN_USER@$machine "pkill sysbenc; rm -f ${RESULTS_DIR%/}/{*$AIO_MODE*.log,*$AIO_MODE*.txt}; mkdir -p $MULTICLIENT_ROOT_DIR;"
done
wait

./multiclient_setup_initiate.py $REMOTE_HOSTS_FILE $MULTICLIENT_CONFIG_FILE

# separate step for sysbench startup
if [[ $ENABLE_PBENCH -eq 1 ]]; then
    pbench-clear-tools
    pbench-clear-results
    pbench-register-tool-set

    for machine in $(cat $REMOTE_HOSTS_FILE); do
      echo "....setting sysbench run name in file; clearing pbench tool-set on client: $machine"
    	ssh root@$machine "${MULTICLIENT_ROOT_DIR%/}/set_result_name.sh; pbench-clear-tools; pbench-clear-results" &
    done
    wait

    for machine in $(cat $REMOTE_HOSTS_FILE); do
      echo "....registering pbench tool-set on client: $machine"
    	pbench-register-tool-set --remote=$machine --label=sysbenchguest &
    done
    wait

    DESCRIP="$CONFIG_NAME"_"$AIO_MODE"_OLTP_"$OLTP_TABLE_SIZE"_"$(date +'%Y-%m-%d_%H:%M:%S')"
    benchmark_run_dir=/var/lib/pbench-agent/$DESCRIP

    for thread in $THREADS; do
      echo "....killing pbench tools while running for thread count: $thread"
      pbench-kill-tools > /dev/null 2>&1
      # pbench-user-benchmark --config=$DESCRIP -- "./start_sysbench_remote.sh $thread"
      echo "....running pbench+sysbench for thread count: $thread"
      benchmark_results_dir=$benchmark_run_dir/$thread
      pbench-metadata-log --dir=$benchmark_results_dir beg
      pbench-start-tools --group=default --iteration=$thread --dir=$benchmark_results_dir
      ./start_sysbench_remote.sh $thread
      pbench-stop-tools --group=default --iteration=$thread --dir=$benchmark_results_dir
      pbench-postprocess-tools --group=default --iteration=$thread --dir=$benchmark_results_dir
      pbench-metadata-log --dir=$benchmark_results_dir end
    done

    for machine in $(cat $REMOTE_HOSTS_FILE); do
      ssh root@$machine "echo '<------------- sysbench test END' >> ${RESULTS_DIR%/}/$E_LOG_FILENAME"
      ssh root@$machine "echo >> ${RESULTS_DIR%/}/$E_LOG_FILENAME"
      results_name=$(ssh root@$machine cat ${RESULTS_DIR%/}/sysbench_run_result_name)
      ssh root@$machine "cp -p ${RESULTS_DIR%/}/$results_name.txt ${benchmark_run_dir%/}/"$results_name"_"$OLTP_TABLE_SIZE"_"$machine".txt"
    done

else
    for machine in $(cat $REMOTE_HOSTS_FILE); do
    	echo "....running sysbench on client: $machine"
    	ssh root@$machine "${MULTICLIENT_ROOT_DIR%/}/run-sysbench.sh 2>&1" &
    done
    wait
fi

for machine in $(cat $REMOTE_HOSTS_FILE); do
    results_name=$(ssh root@$machine cat ${RESULTS_DIR%/}/sysbench_run_result_name)
    scp root@$machine:${RESULTS_DIR%/}/$results_name.txt /tmp/"$results_name"_"$OLTP_TABLE_SIZE"_"$machine".txt
done
wait

# move-results is taken care of in collect_sysbench_results script
