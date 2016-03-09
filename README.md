# multivm_db_bench

Some automation scripts to use for running sysbench benchmarks
for different thread counts on multiple Virtual Machines, for MariaDB.

This project is WIP. Use at your own risk
(if you're able to get it! `:-)`)

## Usage

For entry point use (from within `scripts/` folder):

```
./automate_sysbench.sh <vm seq# BEGIN> <vm seq# END>
```

- For example: `./automate_sysbench.sh 2 4` would run this setup
  on vm2, vm3 and vm4.
- Assuming: vms are named in sequential order, as vm1, vm2 etc..
  Example, on doing `virsh list` we would get vm1, vm2, etc..

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

  1. Before starting, change the mysql password in config file `my.cnf.example`
  as under the following section/parameter:

    ```
    [client]
    password=90feet-
    ```

  2. Before running, ensure the following files in the same directory as `automate_sysbench.sh`:

    ```
    multivm_setup_initiate.py
    my.cnf.example
    setup_sysbench.sh
    start_sysbench_tests.sh

    sysbench_utilities.tgz
    sysbench-0.4.12.tar.gz <optional; downloaded by script if not present>
    ```

  3. The VM(s) should be up and running, and have the folders already mounted,
    as per the aio modes.

      - `/home/native` with `aio=native`
      - `/home/threads` with `aio=threads`

- __NOTE__: `sysbench_utilities.tgz` is currently not part of this repo. Will release soon.

- __FYI__: Inside VMs, these scripts run:

  ```
  ./start_sysbench_tests.sh root <mysql pass>
  ./setup_sysbench.sh <mysql pass> <mysql old pass>
  # leave old pass blank if running first time
  ```

## TODO:

  1. Ansiblize.

  2. fix this really nasty README.md

  3. Verify that this setup of aio modes actually works..
     As in:
     - `--datadir=/var/lib/mysql` currently, when we see
       `systemctl status mysql`. While innodb files are
       stored under filesystems mounted as per aio modes.
     - Also, `#data=/home/native/mysql_data` .. is as visible,
       commented out in /etc/my.cnf currently.

  4. Add vm xml files; demo script; disk formatting/attachment/mount
     scripts.

  5. Check the timeout in pssh python module; i.e, on uncommenting
     the `execute_script()` method for `start_sysbench_tests.sh`,
     the output is not clear, whether the command has actually finished?
     sysbench take a lot of time to run, hours sometimes, depending on
     configuration. Hence, we need to add this check.
