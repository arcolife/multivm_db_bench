#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

[ $# = 0 ] && {
  echo "usage: ./run_sysbench_display_stats_hack.sh <multivm.config path>";
  echo "example: ./run_sysbench_display_stats_hack.sh multivm.config";
  exit -1;
}

source $1

# this is done through python file currently
# # first prepare databases on all VMs, then execute sysbench
# for i in `cat /tmp/vm_hostnames`; do
#   echo "running sysbench on: $i"
#   ssh root@$i "${MULTIVM_ROOT_DIR%/}/prepare_sysbench_tests.sh"
# done

# separate step for sysbench startup
for i in `cat /tmp/vm_hostnames`; do
  echo "running sysbench on: $i"
  ssh root@$i "${MULTIVM_ROOT_DIR%/}/start_sysbench.sh"
done

for i in `cat /tmp/vm_hostnames`; do
    echo "displaying results file on: $i"
    ssh root@$i "ls -lh ${RESULTS_DIR%/}"
done
