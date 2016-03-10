#!/bin/bash

MYSQL_USERNAME=$1
MYSQL_PASS=$2
aio=$3

if [[ ! $aio =~ ^(native|threads)$ ]]; then
  echo "wrong aio mode selected. choose native/threads"
  exit 1
fi

cd /root/scripts/

buffer_pool_size=$(grep buffer_pool_size /etc/my.cnf | awk -F' ' '{print $3}')
release_tag=$(uname -r | awk -F'-' '{print $2}' |  awk -F'.' '{print $1}')
rhel_version=$(awk -F' ' '{print $(NF-1)}' /etc/redhat-release)
db_ver=$(mysql --version  | awk -F' ' '{print $5}')

# # for aio in native threads; do
systemctl stop mysql

sed -i 's#innodb_log_group_home_dir.*#innodb_log_group_home_dir = /home/'$aio'/mysql_data#'g /etc/my.cnf
sed -i 's#innodb_data_home_dir.*#innodb_data_home_dir = /home/'$aio'/mysql_data#'g /etc/my.cnf

systemctl start mysql
if [ ! $? -eq 0 ]; then
  systemctl restart mysql
  if [ ! $? -eq 0 ]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S'): MariaDB failed to start.." >> /tmp/sysbench."$aio".error.log
    exit 1
  fi
fi

# mysqladmin -u$MYSQL_USERNAME -p$MYSQL_PASS create sbtest
# mysqladmin -u$MYSQL_USERNAME -p$MYSQL_PASS drop sbtest
# mysql -e 'drop database sbtest; create database sbtest'
# rm -rf /var/lib/mysql/sbtest/
mysql -e 'drop database sbtest'
mysql -e 'create database sbtest'

if [ ! $? -eq 0 ]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S'): unable to create database sbtest.." >> /tmp/sysbench."$aio".error.log
    exit 1
fi

# To prepare the database and load data
echo "preparing oltp tables for $aio.."
sysbench prepare --test=oltp --mysql-table-engine=innodb --oltp-table-size=1000000 --mysql-user=$MYSQL_USERNAME --mysql-password=$MYSQL_PASS
if [ ! $? -eq 0 ]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S'): failed to prepare database sbtest.." >> /tmp/sysbench."$aio".error.log
    exit 1
fi
echo "done preparing oltp tables for $aio.."

# run the workload (add --max-requests=<n> to run certain number of transactions, default 10000)
# sysbench --test=oltp --num-threads=12 --max-requests=1000000 --max-time=900 run > test.log
echo "starting sysbench test for $aio.."
./run-sysbench-series.sh >> results/"$release_tag"_r"$rhel_version"_"${db_ver::-1}"_"$buffer_pool_size"_"$aio"_"$(date +'%Y-%m-%d_%H:%M:%S')".txt 2>&1 &
# if [ ! $? -eq 0 ]; then
#     echo "$(date +'%Y-%m-%d %H:%M:%S'): failed to run sysbench.." >> /tmp/sysbench."$aio".error.log
#     exit 1
# fi
# echo "ending sysbench test for $aio.."

# # done
