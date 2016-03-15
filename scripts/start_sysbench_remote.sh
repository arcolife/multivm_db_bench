#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

source ./multivm.config

for machine in $(cat $REMOTE_HOSTS_FILE); do
    echo "running sysbench on client: $machine"
    ssh root@$machine 'source /etc/multivm.config; ${MULTIVM_ROOT_DIR%/}/run-sysbench.sh >> ${RESULTS_DIR%/}/$(hostname)_sysbench.txt 2>&1 &'
done
