#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

source ./multivm.config

thread_count=$1

for machine in $(cat $REMOTE_HOSTS_FILE); do
    echo "running sysbench on client: $machine"
    ssh root@$machine 'source /etc/multivm.config; ${MULTIVM_ROOT_DIR%/}/run-sysbench-pbench.sh '$thread_count' >> ${RESULTS_DIR%/}/$(hostname)_sysbench'$thread_count'.txt 2>&1' &
done
