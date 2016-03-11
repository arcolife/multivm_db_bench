#!/bin/sh
# input time in seconds
# input2 - file name
ntime=$1
date
cat /proc/interrupts > $2_interrupts_start.txt
iostat -x 3 $ntime > $2_iostat.txt 2>&1&
vmstat 3 $ntime > $2_vmstat.txt 2>&1&
mpstat -P ALL 3 $ntime > $2_mpstat.txt 2>&1&
sar -n DEV 3 $ntime > $2_nic.txt 2>&1&
wait
cat /proc/interrupts > $2_interrupts_stop.txt
date

