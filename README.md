# multivm_db_bench

Some automation scripts to use for running sysbench benchmarks
for different thread counts on multiple Virtual Machines, for MariaDB.

This project is WIP. Use at your own risk
(if you're able to get it! `:-)`)

## Usage

NOTE: currently some methods are commented in `multivm_setup_initiate.py`.

- For entry point use:
`./automate_sysbench.sh <vm seq# BEGIN> <vm seq# END>`

Assuming vms are named in sequential order, as vm1, vm2 etc..
Example, on doing `virsh list` we would get vm1, vm2, etc..
So `./automate_sysbench.sh 2 4` would result in running this
setup on vm2, vm3 and vm4.

- Before starting, change the mysql passwords as under
the following fils/sections:

```
multivm_setup_initiate.py: # MYSQL_PASS='90feet-'
my.cnf.example: password=90feet-
```

- Needs the following files in the same directory:

```
multivm_setup_initiate.py
my.cnf.example
setup_sysbench.sh
start_sysbench_tests.sh
sysbench_utilities.tgz
sysbench-0.4.12.tar.gz <optional; downloads if not present>
```

- Inside VMs, these scripts run:

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
