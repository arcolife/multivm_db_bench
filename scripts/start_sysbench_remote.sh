#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

for machine in `cat /tmp/vm_hostnames`; do
  echo "starting sysbench test (pbench enabled) for $AIO_MODE.."
  ssh root@$machine 'source /etc/multivm.config && ${MULTIVM_ROOT_DIR%/}/start_sysbench.sh'
  # ssh root@$machine 'source /etc/multivm.config; ${MULTIVM_ROOT_DIR%/}/run-sysbench-pbench.sh >> ${RESULTS_DIR%/}/$AIO.txt 2>&1 &'
done
