#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

source /etc/multivm.config

if [[ -z $MYSQL_PASS ]]; then
  echo "need MYSQL_PASS as arg 2"
  exit 1
fi

start_mysql_setup(){
  yum-complete-transaction

  echo "[mariadb]
# MariaDB 10.0 RedHat repository list - created 2015-08-20 13:31 UTC
# http://mariadb.org/mariadb/repositories/
name = MariaDB
baseurl = http://yum.mariadb.org/10.0/rhel7-amd64
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=1
" > /etc/yum.repos.d/mariadb.repo

  yum -y install MariaDB-devel  gcc gcc-c++ autoconf automake make libtool \
  zlib zlib-devel openssl-devel

  cd $MULTIVM_ROOT_DIR
  tar xvfz sysbench-0.4.12.tar.gz
  cd sysbench-0.4.12

  sed -i s/AC_PROG_LIBTOOL/#AC_PROG_LIBTOOL\\nAC_PROG_RANLIB/g configure.ac

  ./autogen.sh

  ./configure bindir=/usr/local/bin

  make && make install

  yum install -y MySQL-server

  # mysqld_safe --user=$MYSQL_USERNAME --basedir=/usr --skip-grant-tables &
  systemctl start mysql

  mysqladmin -u $MYSQL_USERNAME --password="$MYSQL_PASS_OLD" password  "$MYSQL_PASS"

  systemctl stop mysql

  cp ${MULTIVM_ROOT_DIR%/}/my.cnf.example /etc/my.cnf

  sed -i 's#user=.*#user='$MYSQL_USERNAME'#'g /etc/my.cnf
  sed -i 's#password=.*#password='$MYSQL_PASS'#'g /etc/my.cnf

  mkdir -p /home/{native,threads}/mysql_data/
  chown -R mysql:mysql /home/{native,threads}/mysql_data/
  chcon -R --type=mysqld_db_t /home/{native,threads}/mysql_data/
  chgrp -R mysql /home/{native,threads}/mysql_data/

  restorecon -R /var/lib/mysql/
  chown -R mysql:mysql /var/lib/mysql/

  mkdir -p $RESULTS_DIR
  systemctl start mysql
  mysql_service_status=$(systemctl status mysql | grep "active (running)")
  if [[ ! -z $mysql_service_status ]]; then
    # mysql instance was found running
    echo "sysbench setup completed!"
  else
    echo "failed to start mysql instance.."
    exit 1
  fi
}

remove_setup_traces(){
  systemctl stop mysql
  yum remove -y MySQL-server
  rm -rf /var/lib/mysql/
  rm -f /home/*/mysql_data/*
  rm -f ${MULTIVM_ROOT_DIR%/}/*
}

cleanup_mysql_setup(){
  systemctl stop mysql
  echo "removing sbtest db.."
  rm -rf /var/lib/mysql/sbtest/
  restorecon -R /var/lib/mysql/
  chown -R mysql:mysql /var/lib/mysql/

  echo "resetting dirs for $AIO_MODE.."
  rm -rf /home/$AIO_MODE/mysql_data/
  mkdir -p /home/$AIO_MODE/mysql_data/
  mkdir -p $RESULTS_DIR

  chown -R mysql:mysql /home/$AIO_MODE/mysql_data/
  chcon -R --type=mysqld_db_t /home/$AIO_MODE/mysql_data/
  chgrp -R mysql /home/$AIO_MODE/mysql_data/

  echo "starting mysql.."
  systemctl start mysql
  mysql_service_status=$(systemctl status mysql | grep "active (running)")
  if [[ ! -z $mysql_service_status ]]; then
    # mysql instance was found running
    echo "mariadb cleanup completed!"
  else
    echo "failed to start mysql instance.."
    exit 1
  fi
}

mysql_service_status=$(systemctl status mysql | grep "not-found")

if [[ ! -z $mysql_service_status ]] || [[ $REINSTALL_OPTION -eq 1 ]]; then
  # mysql service was not found; or forceful reset was made..
  remove_setup_traces
  start_mysql_setup
else
  cleanup_mysql_setup
fi
