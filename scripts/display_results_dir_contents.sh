#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

[ $# = 0 ] && {
  echo "usage: ./display_results_dir_contents.sh <multiclient.config path>";
  echo "example: ./display_results_dir_contents.sh multiclient.config";
  exit -1;
}

MULTICLIENT_CONFIG_FILE=multiclient.config
REMOTE_HOSTS_FILE=client_hostnames.txt

source $MULTICLIENT_CONFIG_FILE

for i in $(cat $REMOTE_HOSTS_FILE); do
    echo "displaying results file on: $i"
    ssh root@$i "echo; date; ls -lh ${RESULTS_DIR%/}; echo; cat ${RESULTS_DIR%/}/*_$AIO_MODE*txt"
    echo "===================================================="
done
