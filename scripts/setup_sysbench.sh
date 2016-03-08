#!/bin/bash

MYSQL_PASS=$1
MYSQL_PASS_OLD=$2

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

systemctl start mysql

mysqladmin -u root --password="$MYSQL_PASS_OLD" password  "$MYSQL_PASS"

systemctl stop mysql

cp /root/my.cnf.example /etc/my.cnf

mkdir -p /home/native/mysql_data/
chown -R mysql:mysql /home/native/mysql_data/
chcon -R --type=mysqld_db_t /home/native/mysql_data/
chgrp -R mysql /home/native/mysql_data/

restorecon -R /var/lib/mysql/
chown -R mysql:mysql /var/lib/mysql/

# mysqld_safe --user=root --basedir=/usr --skip-grant-tables &
# mysqladmin -u root -p password

cd /root/
mkdir -p /root/scripts/results/
mv sysbench_utilities.tgz /root/scripts/
cd /root/scripts/
tar -xvzf sysbench_utilities.tgz
mv tools/ /

systemctl start mysql
