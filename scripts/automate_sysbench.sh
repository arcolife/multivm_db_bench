#!/bin/bash

# for i in $(seq $1 $2); do echo "$i $(arp -e | grep $(virsh domiflist "vm$i" | tail -n 2  | head -n 1 | awk -F' ' '{print $NF}') | tail -n 1 | awk -F' ' '{print $1}')"; done;

AIO_MODE='native'

##############################################
if [[ ! -f sysbench-0.4.12.tar.gz ]]; then
  wget http://pkgs.fedoraproject.org/repo/pkgs/sysbench/sysbench-0.4.12.tar.gz/3a6d54fdd3fe002328e4458206392b9d/sysbench-0.4.12.tar.gz
fi
#
# for ssh_id in `cat hosts.txt | xargs -n1 printf "root@%s\n"`; do
#     ssh $ssh_id ""
#     scp -r /root/sysbench_utilities.tgz $ssh_id:/root/scripts/
# done

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

echo
for i in `cat /tmp/vm_hostnames`; do
  echo "cleaning up on: $i"
  ssh root@$i "ls /root/scripts/ | grep sb_1_io; rm -f /root/scripts/{sb_*,e.log} /tmp/sysbench.log"
  # ssh root@$i rm -rf /root/scripts/results/*;
done

# default: native tests
./multivm_setup_initiate.py /tmp/vm_hostnames my.cnf.example $AIO_MODE
