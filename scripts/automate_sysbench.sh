#!/bin/bash

AIO_MODE='native'
OLTP_TABLE_SIZE=1000000
##############################################
if [[ ! -f sysbench-0.4.12.tar.gz ]]; then
  wget http://pkgs.fedoraproject.org/repo/pkgs/sysbench/sysbench-0.4.12.tar.gz/3a6d54fdd3fe002328e4458206392b9d/sysbench-0.4.12.tar.gz
fi

# for i in `seq $1 $2`; do virsh destroy  vm$i ; done
# for i in `seq $1 $2`; do virsh start  vm$i ; done
# for i  in `cat vm_ips`; ssh root@i "mkfs.xfs /dev/vdb"; done
# ./virt-attach-disk1.sh 8 lvm
# for i in `seq 2 16`; do virsh deattach-disk vm$i vdb --persistent ; done

rm -f /tmp/vm_hostnames
echo "getting hostname/IP for all VMs.."
for i in $(seq $1 $2); do
  MAC_ADDR=$(virsh domiflist "vm$i" | tail -n 2  | head -n 1 | awk -F' ' '{print $NF}')
  echo $(arp -e | grep $MAC_ADDR | tail -n 1 | awk -F' ' '{print $1}') >> /tmp/vm_hostnames
done
# for i in $(seq $1 $2); do echo "$i $(arp -e | grep $(virsh domiflist "vm$i" | tail -n 2  | head -n 1 | awk -F' ' '{print $NF}') | tail -n 1 | awk -F' ' '{print $1}')"; done;

for i in `cat /tmp/vm_hostnames`; do
  # ssh root@$i "ls -lh /root/scripts/results /root/scripts/"
done

echo
for i in `cat /tmp/vm_hostnames`; do
  echo "attempting to kill sysbench related processes on: $i"
  ssh root@$i 'kill -9 $(pgrep run-sysbench); kill -9 $(pgrep profit3)'
  echo "cleaning up on: $i"
  ssh root@$i "rm -f /root/scripts/results/{*$AIO*.log,*$AIO*.txt}"
done

./multivm_setup_initiate.py /tmp/vm_hostnames my.cnf.example $AIO_MODE $OLTP_TABLE_SIZE
