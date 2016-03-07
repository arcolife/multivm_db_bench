#!/bin/bash

# mysql -e 'drop database sbtest;create database sbtest'
cd /root/scripts/

buffer_pool_size=$(grep buffer_pool_size /etc/my.cnf | awk -F' ' '{print $3}')
release_tag=$(uname -r | awk -F'-' '{print $2}' |  awk -F'.' '{print $1}')
rhel_version=$(awk -F' ' '{print $(NF-1)}' /etc/redhat-release)
db_ver=$(mysql --version  | awk -F' ' '{print $5}')

for aio in native threads; do

  systemctl stop mysql

  sed -i 's#innodb_log_group_home_dir.*#innodb_log_group_home_dir = /home/$aio/mysql_data#'g /etc/my.cnf
  sed -i 's#innodb_data_home_dir.*#innodb_data_home_dir = /home/$aio/mysql_data#'g /etc/my.cnf

  rm -rf /var/lib/mysql/sbtest/
  systemctl start mysql
  if [ ! $? -eq 0 ]; then
    systemctl restart mysql
    if [ ! $? -eq 0 ]; then
      echo "$(date +'%Y-%m-%d %H:%M:%S'): MariaDB failed to start.." > /tmp/sysbench.log
      exit 1
    fi
  fi

  # # mysqladmin -f -uroot -p100yard- drop sbtest
  # mysqladmin -uroot -p100yard- create sbtest
  # mysql -e 'drop database sbtest; create database sbtest'
  mysql -e 'create database sbtest'
  if [ ! $? -eq 0 ]; then
      echo "$(date +'%Y-%m-%d %H:%M:%S'): unable to create database sbtest.." > /tmp/sysbench.log
      exit 1
  fi

  # To prepare the database and load data
  sysbench prepare --test=oltp --mysql-table-engine=innodb --oltp-table-size=10000000
  if [ ! $? -eq 0 ]; then
      echo "$(date +'%Y-%m-%d %H:%M:%S'): failed to prepare database sbtest.." > /tmp/sysbench.log
      exit 1
  fi

  # run the workload (add --max-requests=<n> to run certain number of transactions, default 10000)
  # sysbench --test=oltp --num-threads=12 --max-requests=1000000 --max-time=900 run > test.log
  ./run-sysbench-series.sh > results/"$release_tag"_r"$rhel_version"_"${db_ver::-1}"_"$buffer_pool_size"_"$aio".txt 2>&1
  if [ ! $? -eq 0 ]; then
      echo "$(date +'%Y-%m-%d %H:%M:%S'): failed to run sysbench.." > /tmp/sysbench.log
      exit 1
  fi

done
