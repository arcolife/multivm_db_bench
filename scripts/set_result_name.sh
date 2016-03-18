#!/bin/bash

source /etc/multivm.config

buffer_pool_size=$(grep buffer_pool_size /etc/my.cnf | awk -F' ' '{print $3}')
release_tag=$(uname -r | awk -F'-' '{print $2}' |  awk -F'.' '{print $1}')
rhel_version=$(awk -F' ' '{print $(NF-1)}' /etc/redhat-release)
db_ver=$(mysql --version  | awk -F' ' '{print $5}')

RESULTS_NAME="$release_tag"_r"$rhel_version"_"${db_ver::-1}"_"$buffer_pool_size"_"$OLTP_TABLE_SIZE"_"$AIO_MODE"_"$(date +'%Y-%m-%d_%H:%M:%S')"

echo $RESULTS_NAME > ${RESULTS_DIR%/}/sysbench_run_result_name

echo >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
echo >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
echo "sysbench test for $RESULTS_NAME (pbench enabled) START: ------------------->" >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
date >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
uname -a >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
