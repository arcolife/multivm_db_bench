#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

source /etc/multivm.config

buffer_pool_size=$(grep buffer_pool_size /etc/my.cnf | awk -F' ' '{print $3}')
release_tag=$(uname -r | awk -F'-' '{print $2}' |  awk -F'.' '{print $1}')
rhel_version=$(awk -F' ' '{print $(NF-1)}' /etc/redhat-release)
db_ver=$(mysql --version  | awk -F' ' '{print $5}')

RESULTS_NAME="$release_tag"_r"$rhel_version"_"${db_ver::-1}"_"$buffer_pool_size"_"$AIO_MODE"_"$(date +'%Y-%m-%d_%H:%M:%S')"

export PARAMS="--test=oltp --mysql-table-engine=innodb \
              --oltp-table-size=$OLTP_TABLE_SIZE \
              --max-time=$TIME --max-requests=0 \
              --mysql-user=$MYSQL_USERNAME --mysql-password=$MYSQL_PASS run"

echo >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
echo >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
echo "sysbench test for $RESULTS_NAME START: ------------------->" >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
date >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
uname -a >> ${RESULTS_DIR%/}/$E_LOG_FILENAME

for i in $THREADS; do
    ( printf "%3d: [%d secs] " $i $TIME
    ${MULTIVM_ROOT_DIR%/}/profit3_sysbench.sh 200 ${RESULTS_DIR%/}/"$AIO_MODE"_sb_$i
    sysbench $PARAMS --num-threads=$i |
    grep transactions: | tee -a ${RESULTS_DIR%/}/$E_LOG_FILENAME
    ) >> ${RESULTS_DIR%/}/$RESULTS_NAME.txt
done

echo "<------------- sysbench test END" >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
echo >> ${RESULTS_DIR%/}/$E_LOG_FILENAME
