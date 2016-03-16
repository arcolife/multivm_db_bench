#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

[ $# = 0 ] && {
  echo "usage: ./display_results_dir_contents.sh <multivm.config path>";
  echo "example: ./display_results_dir_contents.sh multivm.config";
  exit -1;
}

source $1

for i in $(cat $REMOTE_HOSTS_FILE); do
    echo "displaying results file on: $i"
    ssh root@$i "echo; date; ls -lh ${RESULTS_DIR%/}; echo; cat ${RESULTS_DIR%/}/*_$AIO_MODE*txt"
    echo "===================================================="
done
