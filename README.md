# multivm_db_bench

Some automation scripts to use for running sysbench benchmarks
for different thread counts on multiple Virtual Machines, for MariaDB.

This project is WIP. Use at your own risk
(if you're able to get it! `:-)`)

## Usage

Refer to Prerequisites section first.
For entry point use (from within `scripts/` folder):

```
./automate_sysbench.sh <multivm.config path> <vm1> <vm2> <vm3>...
```

- For example: `./automate_sysbench.sh  multivm.config vm{2..4}` would run this setup
  on vm2, vm3 and vm4.
- Assuming: vms are named in sequential order, as vm1, vm2 etc..
  Example, on doing `virsh list` we would get vm1, vm2, etc..

__IMPORTANT__

  There's currently an issue with pssh and background process. It's being exited
  when ssh session ends.. This affects the execution of sysbench on VMs. So run
  this software as demonstrated in following example:

  - step 1: `./automate_sysbench.sh  multivm.config vm{1..8}`
  - step 2: `./run_sysbench_display_stats_hack.sh`
  - ..then check if results are popping up in a VM, under `/root/scripts/results`


__NOTE__:
  - Currently some pssh methods might be commented out in
    `multivm_setup_initiate.py`. Use as per requirement..
  - Also, if you're using `parallel-ssh==0.80.7` python2 package less than 0.90,
    you might face ascii decoding related error.
      - Just edit the file: `/usr/lib/python2.7/site-packages/pssh/ssh_client.py`
      (as shown in traceback), and change the 'ascii' part to 'utf-8' as shown below:

      ```
      # change this: output = line.strip().decode('ascii')
      # to this: output = line.strip().decode('utf-8')
      ```

      ..and run again. This is incase, you're uanble to upgrade to 0.90
      (maybe it's not available on pip yet) or any other reason.

## PREREQUISITES

  1. Before starting, if needed, change the mysql password in config file `my.cnf.example`
  as under the following section/parameter:

    ```
    [client]
    user=root
    password=90feet-
    ```

  2. Ensure that following major params are present corretly assigned under `multivm.config`:

    ```
    AIO_MODE='native'
    OLTP_TABLE_SIZE=1000000
    ```
    Check other params as per need.

  3. Before running, ensure the following files in the same directory as `automate_sysbench.sh`:

    ```
    multivm_setup_initiate.py
    my.cnf.example
    multivm.config
    setup_sysbench.sh
    start_sysbench_tests.sh

    sysbench_utilities.tgz
    sysbench-0.4.12.tar.gz <optional; downloaded by script if not present>
    ```

  4. The VM(s) should be up and running, and have the folders already mounted,
    as per the aio modes.

      - `/home/native` with `aio=native`
      - `/home/threads` with `aio=threads`

  5. Install the python2 module `parallel-ssh` via pip.
    (you'd have to temporarily enable epel repo for installing pip on rhel)

  6. You have passwordless ssh access to all VMs from host machine.

- __FYI__: Inside VMs, these scripts run:

  ```
  ./start_sysbench_tests.sh
  ./setup_sysbench.sh
  ```

## TODO:

  1. Ansiblize.

  2. fix this really nasty README.md

  3. Add vm xml files; demo script; disk formatting/attachment/mount
     scripts.

  4. pssh + background process issue debug

  5. add a data collection script, to collect data from all machines at the end of each run
     and if possible, emit them in json formats, ready to be indexed.
