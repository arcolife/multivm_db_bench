#!/bin/bash

# for i in $(seq 1 8); do echo "$i $(arp -e | grep $(virsh domiflist "vm$i" | tail -n 2  | head -n 1 | awk -F' ' '{print $NF}') | tail -n 1 | awk -F' ' '{print $1}')"; done;

if [[ ! -f sysbench-0.4.12.tar.gz ]]; then
  wget http://pkgs.fedoraproject.org/repo/pkgs/sysbench/sysbench-0.4.12.tar.gz/3a6d54fdd3fe002328e4458206392b9d/sysbench-0.4.12.tar.gz
fi
#
# for ssh_id in `cat hosts.txt | xargs -n1 printf "root@%s\n"`; do
#     ssh $ssh_id ""
#     scp -r /root/sysbench_utilities.tgz $ssh_id:/root/scripts/
# done

rm -f /tmp/vm_hostnames

for i in $(seq $1 $2); do
  echo $(arp -e | grep $(virsh domiflist "vm$i" | tail -n 2  | head -n 1 | awk -F' ' '{print $NF}') | tail -n 1 | awk -F' ' '{print $1}') >> /tmp/vm_hostnames
done

./multivm_setup_initiate.py /tmp/vm_hostnames my.cnf.example
