#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

AIO_MODE=$1
MYSQL_PASS=$2
MYSQL_PASS_OLD=$3

if [[ -z $MYSQL_PASS ]]; then
  echo "need MYSQL_PASS as arg 2"
  exit 1
fi

start_mysql_setup(){
  yum-complete-transaction

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

  # mysqld_safe --user=root --basedir=/usr --skip-grant-tables &
  systemctl start mysql

  mysqladmin -u root --password="$MYSQL_PASS_OLD" password  "$MYSQL_PASS"

  systemctl stop mysql

  cp /root/my.cnf.example /etc/my.cnf

  mkdir -p /home/{native,threads}/mysql_data/
  chown -R mysql:mysql /home/{native,threads}/mysql_data/
  chcon -R --type=mysqld_db_t /home/{native,threads}/mysql_data/
  chgrp -R mysql /home/{native,threads}/mysql_data/

  restorecon -R /var/lib/mysql/
  chown -R mysql:mysql /var/lib/mysql/

  cd /root/
  mkdir -p /root/scripts/results/
  mv sysbench_utilities.tgz /root/scripts/
  cd /root/scripts/
  tar -xvzf sysbench_utilities.tgz
  mv tools/ /
  systemctl start mysql
  mysql_service_status=$(systemctl status mysql | grep "active (running)")
  if [[ ! -z $mysql_service_status ]]; then
    # mysql instance was found running
    echo "sysbench setup completed!"
  else
    echo "failed to start mysql instance.."
    exit 1
}

remove_setup_traces(){
  systemctl stop mysql
  yum remove -y MySQL-server
  rm -rf /var/lib/mysql/
  rm -f /home/*/mysql_data/*
  rm -rf /tools
}

cleanup_mysql_setup(){
  systemctl stop mysql

  rm -rf /var/lib/mysql/sbtest/
  restorecon -R /var/lib/mysql/
  chown -R mysql:mysql /var/lib/mysql/

  rm -f /home/$AIO_MODE/mysql_data/
  mkdir -p /home/$AIO_MODE/mysql_data/

  chown -R mysql:mysql /home/$AIO_MODE/mysql_data/
  chcon -R --type=mysqld_db_t /home/$AIO_MODE/mysql_data/
  chgrp -R mysql /home/$AIO_MODE/mysql_data/

  systemctl start mysql
  mysql_service_status=$(systemctl status mysql | grep "active (running)")
  if [[ ! -z $mysql_service_status ]]; then
    # mysql instance was found running
    echo "sysbench cleanup completed!"
  else
    echo "failed to start mysql instance.."
    exit 1
}

mysql_service_status=$(systemctl status mysql | grep "not-found")

if [[ -z $mysql_service_status ]]; then
  # mysql service was found
  cleanup_mysql_setup
else
  remove_setup_traces
  start_mysql_setup
