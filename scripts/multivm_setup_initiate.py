#!/usr/bin/env python2
# coding: utf-8

# Author: Archit Sharma <archit.py@gmail.com>

import os, sys
import configparser
from pssh import ParallelSSHClient, utils

# utils.enable_host_logger()

USERNAME='root'
DIRNAME = '/root/'
UTIL_NAMES = ['sysbench_utilities.tgz', 'sysbench-0.4.12.tar.gz', 'my.cnf.example']
SCRIPT_NAMES = ['setup_sysbench.sh', 'start_sysbench_tests.sh']
# SCRIPT_NAMES = ['automate_sysbench.sh', 'setup_sysbench.sh',
#                 'multivm_setup_initiate.py', 'start_sysbench_tests.sh']

FILENAMES = SCRIPT_NAMES + UTIL_NAMES


def display_files(client, hosts, msg, files_to_display, target_dir):
    print(msg)
    output = client.run_command('ls -lh ' + os.path.join(target_dir, '{%s}' %
                                                (','.join(files_to_display))))
    client.get_exit_codes(output)
    for host in hosts:
        print("host: %s -- exit_code: %s" %(host, output[host]['exit_code']))
        for line in output[host]['stdout']: print line
        print

def make_executable(client, hosts, target_files, target_dir):
    print("changing mode +x for all scripts..\n")
    output = client.run_command('chmod +x ' + os.path.join(target_dir, '{%s}' %
                                                (','.join(target_files))))
    client.get_exit_codes(output)
    for host in hosts:
        print("host: %s -- exit_code: %s" %(host, output[host]['exit_code']))
        try:
            for line in output[host]['stdout']: print line
        except:
            pass

def copy_files(client, files_to_copy, target_dir):
    print("\ncopying file..\n")
    for filename in files_to_copy:
        client.copy_file('./%s'%(filename),
                        os.path.join(target_dir, '%s' % (filename)))

    client.pool.join()

def delete_files(client, hosts, files_to_delete, target_dir):
    print("\ndeleting file..\n")
    output = client.run_command('rm -f ' + os.path.join(target_dir, '{%s}' %
                                                (','.join(files_to_delete))))
    client.get_exit_codes(output)
    for host in hosts:
        print("host: %s -- exit_code: %s" %(host, output[host]['exit_code']))

def record_output(generator_object, host, script_name):
    log_file = '/tmp/%s.%s.log' % (host, script_name)
    f = open(log_file, 'wb')
    print("Hold on.. Logging to: %s" % log_file)
    for line in generator_object:
        f.write(line.encode('utf-8') + "\n")
    f.close()

def execute_script(client, hosts, target_dir, script_name, args, nohup=False):
    script_path =  os.path.join(target_dir, script_name)
    print("\nexecuting script: '%s %s'..\n" % (script_path, args))
    if nohup:
        CMD = 'nohup  %s %s > /tmp/%s.out 2> /tmp/%s.err < /dev/null &' % \
                            (script_path, args, script_name, script_name)
    else:
        CMD = '%s %s' % (script_path, args)

    output = client.run_command(CMD)
    client.get_exit_codes(output)
    for host in hosts:
        print("host: %s -- exit_code: %s" %(host, output[host]['exit_code']))
        # for line in output[host]['stdout']: print line
        record_output(output[host]['stdout'], host, script_name)

if __name__=='__main__':
    hosts = set(open(sys.argv[1], 'rb').read().splitlines())

    config = configparser.ConfigParser()
    config.read(sys.argv[2])

    while '' in hosts: hosts.remove('')
    client = ParallelSSHClient(hosts, user=USERNAME)

    # display_files(client, hosts, "\noutput BEFORE DELETING files..\n",
    # FILENAMES, DIRNAME)
    # delete_files(client, hosts, FILENAMES, DIRNAME)
    # display_files(client, hosts, "\noutput AFTER DELETING files..\n",
    # FILENAMES, DIRNAME)
    # display_files(client, hosts, "\noutput BEFORE COPYING files..\n",
    #             FILENAMES, DIRNAME)
    copy_files(client, FILENAMES, DIRNAME)
    make_executable(client, hosts, SCRIPT_NAMES, DIRNAME)
    display_files(client, hosts, "\noutput AFTER COPYING files..\n",
                FILENAMES, DIRNAME)

    execute_script(client, hosts, DIRNAME, 'setup_sysbench.sh',
                config.get('client', 'password'))
    # execute_script(client, hosts, DIRNAME, 'start_sysbench_tests.sh',
    #                 '%s %s' % (USERNAME, config.get('client', 'password')),
    #                 nohup=True)

    # OPTIONAL: setup_sysbench script makes it sure that previous installations
    # are removed. So you won't probably need this. But, just in case,
    # if mysql installation exists previously, supply old password as well
    # execute_script(client, hosts, DIRNAME, 'setup_sysbench.sh',
    #                 '%s %s' % (config.get('client', 'password'),
    #                            config.get('client', 'password')))
