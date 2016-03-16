# multivm_db_bench

Some automation scripts to use for running sysbench benchmarks
for different thread counts on multiple Virtual Machines, for MariaDB.

This project is WIP. Use at your own risk `:-)`

## Usage

__Refer to Prerequisites section first.__

__IMPORTANT__

- Next time, you run `automate_sysbench.sh` after maybe changing
  `AIO_MODE`, sysbench/mariadb setup won't be installed again,
  but would only be cleaned up. If you wanna forcefully reinstall
  sysbench, be sure to update `REINSTALL_OPTION=1` in `multivm.config`.

- `ENABLE_PBENCH=1` by default in multivm.config. Change to 0
  or empty string, if not needed.

#############

- For entry point use (from within `scripts/` folder):

```
# usage:
./automate_sysbench.sh <multivm.config path> <vm1> <vm2> <vm3>...

# example (use std output/error redirection to file since this runs for long)
./automate_sysbench.sh  multivm.config vm{1..8} >> sysbench.log 2>&1 &
```

- Display contents of results dir (check whether they start filling up..)

```
./display_results_dir_contents.sh <multivm.config path>
```

- Later, on completion (in an hour or so), use this to collect all results..

```
./collect_sysbench_results.sh <multivm.config path>
```

#############

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

  3. Before running, ensure all files in the same directory as
     `automate_sysbench.sh`, i.e., you're supposed to run this from under
     `scripts/` folder in this repo. This is until there's a packaged release.

  4. The VM(s) should be up and running, and have the folders already mounted,
    as per the aio modes.

      - `/home/native` with `aio=native`
      - `/home/threads` with `aio=threads`

  5. Install the python2 module `parallel-ssh` via pip, on your host.
    (you'd have to temporarily enable epel repo for installing pip on rhel)

  6. Ensure you have passwordless ssh access to all VMs from host machine.

## TODO:

  1. Ansiblize.

  2. Add vm xml files; demo script; disk formatting/attachment/mount
     scripts.
