#!/bin/bash

set -e

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    pbench-kill-tools
    pbench-clear-results
    exit 1
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

[ $# = 0 ] && {
    echo "Usage: ./automate_sysbench.sh <multivm.config path> <vm1> <vm2> <vm3>..."
    echo "Refer to README Usage section for more details.."
    echo "example: ./automate_sysbench.sh multivm.config vm{1..8}"
    exit -1
}

# path to 'multivm.config'. Should be present in same dir as this script.
# Contains env vars: AIO mode, results dir name etc..
# This file would also be copied to all vms.
multivm_config_file=$1

shift 1
VM_LIST=$*

source $multivm_config_file


if [[ ! $(basename $multivm_config_file) =~ ^multivm\.config$ ]]; then
    echo "need multivm.config as 1st argument!" > sysbench.$AIO_MODE.log
    exit -1
fi

if [[ ! -f $multivm_config_file ]]; then
    echo "config file doesn't exist!" > sysbench.$AIO_MODE.log
    exit -1
fi

# This file would be populated with *currently running* VM hostnames/IPs

if [[ $(pgrep automate_sysben | wc -l) -gt 2 ]]; then
  echo "more than 1 automate_sysbench scripts are currently running. Killing all." > sysbench.$AIO_MODE.log
  echo "Committing suicide. Run me again to achieve nirvana!" >> sysbench.$AIO_MODE.log
  pgrep automate_sysben | xargs kill -9
  exit -1
fi

echo > sysbench.$AIO_MODE.log

##############################################
if [[ ! -f sysbench-0.4.12.tar.gz ]]; then
    wget $DOWNLOAD_LINK
fi

# for i in `seq $beg $end`; do virsh destroy  vm$i ; done
# for i in `seq $beg $end`; do virsh start  vm$i ; done
# for i  in `cat vm_ips`; ssh $VM_LOGIN_USER@i "mkfs.xfs /dev/vdb"; done
# ./virt-attach-disk1.sh 8 lvm
# for i in `seq 2 16`; do virsh deattach-disk vm$i vdb --persistent ; done

rm -f $REMOTE_HOSTS_FILE
echo "....getting hostname/IP for all clients."
for current_vm in $VM_LIST; do
    if [[ -z $(virsh domstate $current_vm | grep running) ]]; then
	echo  "......$current_vm was found to be not running currently! moving on.."
    else
	MAC_ADDR=$(virsh domiflist "$current_vm" 2>&1 | tail -n 2  | head -n 1 | awk -F' ' '{print $NF}')
	echo $(arp -e | grep $MAC_ADDR | tail -n 1 | awk -F' ' '{print $1}') >> $REMOTE_HOSTS_FILE
    fi
done

if [[ ! -s $REMOTE_HOSTS_FILE ]]; then
    echo "..$REMOTE_HOSTS_FILE was found to be empty after trying to store IPs of supplied (running) clients !"
    exit 1
fi

echo
for machine in $(cat $REMOTE_HOSTS_FILE); do
    echo "....attempting to kill sysbench related pids, clear cache & set up bench scripts on: $machine"
    ssh $VM_LOGIN_USER@$machine "pkill sysbenc; rm -f ${RESULTS_DIR%/}/{*$AIO*.log,*$AIO*.txt}; mkdir -p $MULTIVM_ROOT_DIR;"
done

./multivm_setup_initiate.py $REMOTE_HOSTS_FILE $multivm_config_file

# separate step for sysbench startup
if [[ $ENABLE_PBENCH -eq 1 ]]; then
    pbench-clear-tools
    pbench-clear-results
    pbench-register-tool-set

    for machine in $(cat $REMOTE_HOSTS_FILE); do
      echo "....setting sysbench run name in file; clearing pbench tool-set on client: $machine"
    	ssh root@$machine "${MULTIVM_ROOT_DIR%/}/set_result_name.sh; pbench-clear-tools; pbench-clear-results" &
    done
    wait

    for machine in $(cat $REMOTE_HOSTS_FILE); do
      echo "....registering pbench tool-set on client: $machine"
    	pbench-register-tool-set --remote=$machine --label=sysbenchguest &
    done
    wait

    DESCRIP="$CONFIG_NAME"_"$AIO_MODE"_OLTP_"$OLTP_TABLE_SIZE"_"$(date +'%Y-%m-%d_%H:%M:%S')"
    benchmark_run_dir=/var/lib/pbench-agent/$DESCRIP

    for thread in $THREADS; do
      echo "....killing pbench tools while running for thread count: $thread"
      pbench-kill-tools > /dev/null 2>&1
      # pbench-user-benchmark --config=$DESCRIP -- "./start_sysbench_remote.sh $thread"
      echo "....running pbench+sysbench for thread count: $thread"
      benchmark_results_dir=$benchmark_run_dir/$thread
      pbench-metadata-log --dir=$benchmark_results_dir beg
      pbench-start-tools --group=default --iteration=$thread --dir=$benchmark_results_dir
      ./start_sysbench_remote.sh $thread
      pbench-stop-tools --group=default --iteration=$thread --dir=$benchmark_results_dir
      pbench-postprocess-tools --group=default --iteration=$thread --dir=$benchmark_results_dir
      pbench-metadata-log --dir=$benchmark_results_dir end
    done

    for machine in $(cat $REMOTE_HOSTS_FILE); do
      ssh root@$machine "echo '<------------- sysbench test END' >> ${RESULTS_DIR%/}/$E_LOG_FILENAME"
      ssh root@$machine "echo >> ${RESULTS_DIR%/}/$E_LOG_FILENAME"
      ssh root@$machine "cp -p ${RESULTS_DIR%/}/$E_LOG_FILENAME $benchmark_run_dir"
    done

else

    for machine in $(cat $REMOTE_HOSTS_FILE); do
    	echo "....running sysbench on client: $machine"
    	ssh root@$machine "${MULTIVM_ROOT_DIR%/}/run-sysbench.sh >> ${RESULTS_DIR%/}/"$machine"_sysbench.txt 2>&1" &
    done
    wait
fi

# move-results is taken care of in collect_sysbench_results script
