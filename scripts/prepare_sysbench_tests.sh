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

systemctl stop mysql

sed -i 's#innodb_log_group_home_dir.*#innodb_log_group_home_dir = /home/'$AIO_MODE'/mysql_data#'g /etc/my.cnf
sed -i 's#innodb_data_home_dir.*#innodb_data_home_dir = /home/'$AIO_MODE'/mysql_data#'g /etc/my.cnf
sed -i 's#\#data=.*#\#data=/home/'$AIO_MODE'/mysql_data#'g /etc/my.cnf

systemctl start mysql
if [ ! $? -eq 0 ]; then
  systemctl restart mysql
  if [ ! $? -eq 0 ]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S'): MariaDB failed to start.." >> /tmp/sysbench."$AIO_MODE".error.log
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
    echo "$(date +'%Y-%m-%d %H:%M:%S'): unable to create database sbtest.." >> /tmp/sysbench."$AIO_MODE".error.log
    exit 1
fi

# To prepare the database and load data
echo "preparing oltp tables for $AIO_MODE.."
sysbench prepare --test=oltp --mysql-table-engine=innodb --oltp-table-size=1000000 --mysql-user=$MYSQL_USERNAME --mysql-password=$MYSQL_PASS
if [ ! $? -eq 0 ]; then
    echo "$(date +'%Y-%m-%d %H:%M:%S'): failed to prepare database sbtest.." >> /tmp/sysbench."$AIO_MODE".error.log
    exit 1
fi
echo "done preparing oltp tables for $AIO_MODE.."

# run the test workload (add --max-requests=<n> to run certain number of transactions, default 10000)
# sysbench --test=oltp --num-threads=12 --max-requests=1000000 --max-time=900 run > test.log
