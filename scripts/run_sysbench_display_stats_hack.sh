#!/bin/bash

[ $# = 0 ] && {
  echo "usage: ./run_sysbench_display_stats_hack.sh <multivm.config path>";
  echo "example: ./run_sysbench_display_stats_hack.sh multivm.config";
  exit -1;
}

source $1

for i in `cat /tmp/vm_hostnames`; do
  echo "running sysbench on: $i"
  ssh root@$i "${MULTIVM_ROOT_DIR%/}/start_sysbench_tests.sh"
done

for i in `cat /tmp/vm_hostnames`; do
    echo "displaying results file on: $i"
    ssh root@$i "ls -lh ${RESULTS_DIR%/}"
done
