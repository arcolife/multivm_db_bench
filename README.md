# multiclient_db_bench

Some automation scripts to use for running sysbench benchmarks
for different thread counts on multiple client machines, for MariaDB.

This project is WIP. Use at your own risk `:-)`

## PREREQUISITES

  1. Before starting, if needed, in config file `my.cnf.example`:

  a. change the mysql password as under the following section/parameter:

  ```
  [client]
  user=root
  password=90feet-
  ```

  b. Change these params in `my.cnf.example` as needed:

      ```
      innodb_buffer_pool_size = 8192M
      innodb_additional_mem_pool_size = 256M
      innodb_log_file_size = 2048M
      innodb_log_buffer_size = 128M
      ```

    These numbers are recommended for real tests, but it really depends on your disk space availability. Try to maintain the ratios as specified above.

  2. Ensure that following major params are present corretly assigned under `multiclient.config`:

    ```
    TARGET_VOLUME='/home'
    AIO_MODE='native'
    THREADS="1 2 4 8"
    OLTP_TABLE_SIZE=600000
    ENABLE_PBENCH=0
    ```
    - Set these values as needed and check other params as required.

    - Enabling pbench would result in collection of pbench's results under host's `/var/lib/pbench-agent/` dir.
    pbench should be installed on both host and clients for this to work.

    - Leave `AIO_MODE` as it is, in case you're not testing AIO modes.

    - `TARGET_VOLUME` is where sysbench would be run. A separate dir based on client's IP would be created on that volume

    For more, refer to inline doc within `multiclient.config`.

  3. Before running, ensure all files in the same directory as
     `automate_sysbench.sh`, i.e., you're supposed to run this from under
     `scripts/` folder in this repo. This is until there's a packaged release.

  4. The client(s) should be up and running, and have the folders already mounted,
    as per `$TARGET_VOLUME` in `multiclient.config`.

  5. Install the python2 module `parallel-ssh` via pip, on your host.
    (you'd have to temporarily enable epel repo for installing pip on rhel)

  6. Ensure you have passwordless ssh access to all VMs from host machine.

  7. Store your client IP/hostnames in one-per-line format under `scripts/client_hostnames.txt`

## Usage

__Refer to Prerequisites section first.__

- For entry point use (from within `scripts/` folder):

```
# usage:
./automate_sysbench.sh

# example (use std output/error redirection to file since this runs for long)
./automate_sysbench.sh >> sysbench.log 2>&1 &
```

- Display contents of results dir (check whether they start filling up..)

```
./display_results_dir_contents.sh
```

- Later, on completion (in an hour or so), use this to collect all results..

```
./collect_sysbench_results.sh
```

#############

__NOTE__:

- While using `parallel-ssh==0.80.7` python2 package less than 0.90,
  you might face ascii decoding related error.
    - Just edit the file: `/usr/lib/python2.7/site-packages/pssh/ssh_client.py`
    (as shown in traceback), and change the 'ascii' part to 'utf-8' as shown below:

    ```
    # change this: output = line.strip().decode('ascii')
    # to this: output = line.strip().decode('utf-8')
    ```

    ..and run again. This is incase, you're uanble to upgrade to 0.90
    (maybe it's not available on pip yet) or any other reason.
