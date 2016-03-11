#!/bin/bash

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
# for i in $(seq 1 8); do echo "$i $(arp -e | grep $(virsh domiflist "vm$i" | tail -n 2  | head -n 1 | awk -F' ' '{print $NF}') | tail -n 1 | awk -F' ' '{print $1}')"; done;

if [[ ! -s $hostname_config_file ]]; then
  echo "$hostname_config_file was found to be empty after trying to store IPs of supplied (running) VMs.."
  exit 1
fi

echo
for i in $(cat $hostname_config_file); do
  echo "attempting to kill sysbench related processes on: $i"
  ssh $VM_LOGIN_USER@$i 'kill -9 $(pgrep run-sysbench); kill -9 $(pgrep profit3)'
  echo "cleaning up on: $i"
  ssh $VM_LOGIN_USER@$i "rm -f ${RESULTS_DIR%/}/{*$AIO*.log,*$AIO*.txt}"
  ssh $VM_LOGIN_USER@$i "echo 2 > /proc/sys/vm/drop_caches"
done

./multivm_setup_initiate.py $hostname_config_file $multivm_config_file
