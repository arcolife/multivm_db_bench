#!/bin/bash

source /etc/multivm.config

for i in `cat /tmp/vm_hostnames`; do
  echo "running sysbench on: $i"
  ssh root@$i "${MULTIVM_ROOT_DIR%/}/start_sysbench_tests.sh"
done

for i in `cat /tmp/vm_hostnames`; do
    echo "displaying results file on: $i"
    ssh root@$i "ls -lh ${RESULTS_DIR%/}"
done
