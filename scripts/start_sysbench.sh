#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

source /etc/multivm.config

if [[ ! $AIO_MODE =~ ^(native|threads)$ ]]; then
    echo "wrong AIO_MODE mode selected. choose native/threads"
    exit 1
fi

buffer_pool_size=$(grep buffer_pool_size /etc/my.cnf | awk -F' ' '{print $3}')
release_tag=$(uname -r | awk -F'-' '{print $2}' |  awk -F'.' '{print $1}')
rhel_version=$(awk -F' ' '{print $(NF-1)}' /etc/redhat-release)
db_ver=$(mysql --version  | awk -F' ' '{print $5}')

RESULTS_NAME="$release_tag"_r"$rhel_version"_"${db_ver::-1}"_"$buffer_pool_size"_"$AIO_MODE"_"$(date +'%Y-%m-%d_%H:%M:%S')"

if [[ $ENABLE_PBENCH -eq 1 ]]; then
  echo "starting sysbench test (pbench enabled) for $AIO_MODE.."
  # ${MULTIVM_ROOT_DIR%/}/run-sysbench-pbench.sh $RESULTS_NAME
  # ${MULTIVM_ROOT_DIR%/}/run-sysbench-pbench.sh $RESULTS_NAME >> ${RESULTS_DIR%/}/$RESULTS_NAME.txt 2>&1
  ${MULTIVM_ROOT_DIR%/}/run-sysbench-pbench.sh $RESULTS_NAME >> ${RESULTS_DIR%/}/$RESULTS_NAME.txt 2>&1 &
else
  echo "starting sysbench test for $AIO_MODE.."
  ${MULTIVM_ROOT_DIR%/}/run-sysbench.sh >> ${RESULTS_DIR%/}/$RESULTS_NAME.txt 2>&1 &
fi
