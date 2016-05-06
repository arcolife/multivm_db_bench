#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

source /etc/multiclient.config
echo "Local IP: $MACHINE_IP"

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

  cd $MULTICLIENT_ROOT_DIR
  tar xvfz sysbench-0.4.12.tar.gz
  cd sysbench-0.4.12

  sed -i s/AC_PROG_LIBTOOL/#AC_PROG_LIBTOOL\\nAC_PROG_RANLIB/g configure.ac

  ./autogen.sh

  ./configure bindir=/usr/local/bin

  make && make install

  yum install -y MySQL-server

  # start/stop mysql once to let the tables form.
  # otherwise it will fail.
  systemctl start mysql
  systemctl stop mysql

  cp ${MULTICLIENT_ROOT_DIR%/}/my.cnf.example /etc/my.cnf
  sed -i 's#user=.*#user='$MYSQL_USERNAME'#'g /etc/my.cnf
  sed -i 's#password=.*#password='$MYSQL_PASS'#'g /etc/my.cnf

  sed -i 's#innodb_log_group_home_dir.*#innodb_log_group_home_dir = '${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE'/mysql_data#'g /etc/my.cnf
  sed -i 's#innodb_data_home_dir.*#innodb_data_home_dir = '${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE'/mysql_data#'g /etc/my.cnf
  sed -i 's#datadir=.*#datadir='${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE'/mysql_data#'g /etc/my.cnf


  mkdir -p $RESULTS_DIR
  mkdir -p "${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE"/mysql_data/
  chown -R mysql:mysql "${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE"/mysql_data/
  chcon -R --type=mysqld_db_t "${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE"/mysql_data/
  chgrp -R mysql "${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE"/mysql_data/

  mv /var/lib/mysql/{mysql/,performance_schema/} "${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE"/mysql_data/
  # restorecon -R /var/lib/mysql/
  # chown -R mysql:mysql /var/lib/mysql/
  # mysqld_safe --user=$MYSQL_USERNAME --basedir=/usr --skip-grant-tables &
  systemctl start mysql
  mysqladmin -u $MYSQL_USERNAME --password="$MYSQL_PASS_OLD" password  "$MYSQL_PASS"

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
  # pgrep mysql| xargs kill -9
  mysqladmin -f -uroot  shutdown
  yum remove -y MySQL-server
  rm -rf /var/lib/mysql/
  rm -rf "${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE"/mysql_data/*
  rm -f /etc/my.cnf
}

cleanup_mysql_setup(){
  systemctl stop mysql
  echo "removing sbtest db.."
  rm -rf /var/lib/mysql/sbtest/
  restorecon -R /var/lib/mysql/
  chown -R mysql:mysql /var/lib/mysql/

  echo "resetting dirs for $AIO_MODE.."
  rm -rf "${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE"/mysql_data/
  mkdir -p "${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE"/mysql_data/
  mkdir -p $RESULTS_DIR

  chown -R mysql:mysql "${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE"/mysql_data/
  chcon -R --type=mysqld_db_t "${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE"/mysql_data/
  chgrp -R mysql "${TARGET_VOLUME%/}/$MACHINE_IP/$AIO_MODE"/mysql_data/

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
