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
    ssh root@$machine "${MULTIVM_ROOT_DIR%/}/run-sysbench-pbench.sh $thread_count 2>&1" &
done
wait
