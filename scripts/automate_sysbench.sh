#!/bin/bash

user_interrupt(){
    echo -e "\n\nKeyboard Interrupt detected."
    exit
}

trap user_interrupt SIGINT
trap user_interrupt SIGTSTP

[ $# = 0 ] && {
    echo "Usage: ./automate_sysbench.sh <multivm.config path> <vm1> <vm2> <vm3>...";
    echo "Refer to README Usage section for more details.."
    echo "example: ./automate_sysbench.sh multivm.config vm{1..8}";
    exit -1;
}

# path to 'multivm.config'. Should be present in same dir as this script.
# Contains env vars: AIO mode, results dir name etc..
# This file would also be copied to all vms.
multivm_config_file=$1

shift 1
VM_LIST=$*

if [[ ! $(basename $multivm_config_file) =~ ^multivm\.config$ ]]; then
    echo "need multivm.config as 1st argument!"
    exit -1
fi

if [[ ! -f $multivm_config_file ]]; then
    echo "config file doesn't exist!"
    exit -1
fi

# This file would be populated with *currently running* VM hostnames/IPs
hostname_config_file=/tmp/vm_hostnames

source $multivm_config_file

##############################################
if [[ ! -f sysbench-0.4.12.tar.gz ]]; then
    wget $DOWNLOAD_LINK
fi

# for i in `seq $beg $end`; do virsh destroy  vm$i ; done
# for i in `seq $beg $end`; do virsh start  vm$i ; done
# for i  in `cat vm_ips`; ssh $VM_LOGIN_USER@i "mkfs.xfs /dev/vdb"; done
# ./virt-attach-disk1.sh 8 lvm
# for i in `seq 2 16`; do virsh deattach-disk vm$i vdb --persistent ; done

rm -f $hostname_config_file
echo "getting hostname/IP for all VMs.."
for current_vm in $VM_LIST; do
    if [[ -z $(virsh domstate $current_vm | grep running) ]]; then
	echo  "$current_vm was found to be not running currently! moving on.."
    else
	MAC_ADDR=$(virsh domiflist "$current_vm" 2>&1 | tail -n 2  | head -n 1 | awk -F' ' '{print $NF}')
	echo $(arp -e | grep $MAC_ADDR | tail -n 1 | awk -F' ' '{print $1}') >> $hostname_config_file
    fi
done

if [[ ! -s $hostname_config_file ]]; then
    echo "$hostname_config_file was found to be empty after trying to store IPs of supplied (running) VMs.."
    exit 1
fi

echo
for machine in $(cat $hostname_config_file); do
    echo "attempting to kill sysbench related processes; setting up script & results dirs on: $machine"
    ssh $VM_LOGIN_USER@$machine "pkill sysbenc; rm -f ${RESULTS_DIR%/}/{*$AIO*.log,*$AIO*.txt}; echo 2 > /proc/sys/vm/drop_caches; mkdir -p $MULTIVM_ROOT_DIR;"
done

./multivm_setup_initiate.py $hostname_config_file $multivm_config_file

# separate step for sysbench startup
if [[ $ENABLE_PBENCH -eq 1 ]]; then
    pbench-clear-tools
    pbench-kill-tools
    pbench-clear-results
    pbench-register-tool-set

    for machine in $(cat $hostname_config_file); do
	echo "registering pbench tool-set on client: $machine"
	ssh root@$machine "pbench-clear-tools; pbench-clear-results"
	pbench-register-tool-set --remote=$machine --label=sysbenchguest
    done

    pbench-user-benchmark --config=$CONFIG_NAME -- "./start_sysbench_remote.sh"
    # move-results is taken care of in collect_sysbench_results script
else

    for machine in $(cat $hostname_config_file); do
	echo "running sysbench on client: $machine"
	ssh root@$machine '${MULTIVM_ROOT_DIR%/}/run-sysbench.sh >> ${RESULTS_DIR%/}/"$machine"_sysbench.txt 2>&1 &'
    done
fi
