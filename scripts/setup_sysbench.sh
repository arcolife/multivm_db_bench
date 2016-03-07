#!/bin/bash

echo "
# MariaDB 10.0 RedHat repository list - created 2015-08-20 13:31 UTC
# http://mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/rhel7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
" > /etc/yum.repos.d/mariadb.repo

yum -y install MariaDB-devel  gcc gcc-c++ autoconf automake make libtool \
zlib zlib-devel openssl-devel

cd /root/
tar xvfz sysbench-0.4.12.tar.gz
cd sysbench-0.4.12

sed -i s/AC_PROG_LIBTOOL/#AC_PROG_LIBTOOL\\nAC_PROG_RANLIB/g configure.ac

./autogen.sh

./configure bindir=/usr/local/bin

make && make install

yum install -y MySQL-server

echo "
[client-server]
# Uncomment these if you want to use a nonstandard connection to MariaDB
#socket=/tmp/mysql.sock
#port=3306

# This will be passed to all MariaDB clients
[client]
#password=my_password

# The MariaDB server
[mysqld]
# Directory where you want to put your data
#data=/home/native/mysql_data
# Directory for the errmsg.sys file in the language you want to use
#language=/usr/share/mysql/english
# Create a file where the InnoDB/XtraDB engine stores it's data
innodb_data_home_dir = /home/native/mysql_data
innodb_data_file_path = ibdata1:128M:autoextend
innodb_log_group_home_dir = /home/native/mysql_data
innodb_buffer_pool_size = 8192M
innodb_additional_mem_pool_size = 32M
innodb_log_file_size = 256M
innodb_log_buffer_size = 16M
## write logs every minute instead of every transaction
innodb_flush_log_at_trx_commit = 0
innodb_lock_wait_timeout = 50
innodb_doublewrite = 0
innodb_flush_method = O_DIRECT
innodb_thread_concurrency = 0
innodb_max_dirty_pages_pct = 80
#loose-innodb_file_per_table

# This is the prefix name to be used for all log, error and replication files
log-basename=mysqld

# Enable logging by default to help find problems
##general-log
#log-slow-queries

# include all files from the config directory
#
!includedir /etc/my.cnf.d
" > /etc/my.cnf

mkdir -p /home/native/mysql_data/
chown -R mysql:mysql /home/native/mysql_data/
chcon -R --type=mysqld_db_t /home/native/mysql_data/
chgrp -R mysql /home/native/mysql_data/

restorecon -R /var/lib/mysql/
chown -R mysql:mysql /var/lib/mysql/


mysqld_safe --user=root --basedir=/usr --skip-grant-tables &

mysqladmin -u root -p password

mkdir -p /root/scripts/results/

cd /root/scripts/

tar -xvzf sysbench_utilities.tgz
mv tools/ /
