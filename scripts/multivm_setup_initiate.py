#!/usr/bin/env python2
# coding: utf-8

# Author: Archit Sharma <archit.py@gmail.com>

import os, sys
from pssh import ParallelSSHClient, utils

class SetupMultiVM(object):
    """
    Initiate parallel ssh connection and add basic methods like:
    file display, delete, execute, copy etc..
    """

    def __init__(self, hosts, args):
        self.hosts = hosts
        self.client = ParallelSSHClient(hosts, user=args['VM_LOGIN_USER'])
        self.ROOT_DIR = args['MULTIVM_ROOT_DIR']
        self.AIO_MODE = args['AIO_MODE']
        self.SCRIPT_NAMES = '{%s}' % ','.join(args['SCRIPT_NAMES'])
        self.UTIL_NAMES = '{%s}' % ','.join(args['UTIL_NAMES'])
        self.FILENAMES = ','.join(args['SCRIPT_NAMES'] + args['UTIL_NAMES'])

    def display_files(self, msg=''):
        print("\n%s\n" % msg)
        output = self.client.run_command('ls -lh ' + os.path.join(self.ROOT_DIR,
                                                        '{%s}' % self.FILENAMES))
        self.client.get_exit_codes(output)
        for host in self.hosts:
            print("host: %s -- exit_code: %s" %(host, output[host]['exit_code']))
            for line in output[host]['stdout']: print line
            print

    def make_executable(self):
        print("changing mode +x for all scripts..\n")
        output = self.client.run_command('chmod +x %s' %
                                            os.path.join(self.ROOT_DIR,
                                            self.SCRIPT_NAMES))
        self.client.get_exit_codes(output)
        for host in self.hosts:
            print("host: %s -- exit_code: %s" %(host, output[host]['exit_code']))
            try:
                for line in output[host]['stdout']: print line
            except:
                pass

    def copy_files(self):
        print("\ncopying files to VMs..\n")
        for filename in self.FILENAMES.split(','):
            self.client.copy_file('./%s' % (filename),
                            os.path.join(self.ROOT_DIR, '%s' % (filename)))
        # additionally copy the config file to /etc
        self.client.copy_file('./multivm.config', '/etc/multivm.config')
        # join pool and execute copy commands
        self.client.pool.join()

    def delete_files(self):
        print("\ndeleting existing files..\n")
        output = self.client.run_command('rm -f %s' %
                                            os.path.join(self.ROOT_DIR,
                                            '{%s}' % self.FILENAMES))
        self.client.get_exit_codes(output)
        for host in self.hosts:
            print("host: %s -- exit_code: %s" %(host, output[host]['exit_code']))

    def record_output(self, generator_object, vm_hostname, script_name):
        log_file = '/tmp/%s.%s.%s.log' % (self.AIO_MODE, vm_hostname, script_name)
        f = open(log_file, 'wb')
        print("Hold on.. Logging VM outputs to your host under: %s" % log_file)
        for line in generator_object:
            f.write(line.encode('utf-8') + "\n")
        f.close()

    def execute_script(self, script_name=None, script_args='', nohup=False):
        script_path =  os.path.join(self.ROOT_DIR, script_name)
        print("\nexecuting script: '%s %s'..\n" % (script_path, script_args))
        if nohup:
            CMD = 'nohup  %s %s > /tmp/%s.out 2> /tmp/%s.err < /dev/null &' % \
                            (script_path, script_args, script_name, script_name)
        else:
            CMD = '%s %s' % (script_path, script_args)

        output = self.client.run_command(CMD)
        self.client.get_exit_codes(output)
        for host in self.hosts:
            print("host: %s -- exit_code: %s" %(host, output[host]['exit_code']))
            # for line in output[host]['stdout']: print line
            self.record_output(output[host]['stdout'], host, script_name)

if __name__=='__main__':
    try:
        hosts = set(open(sys.argv[1], 'rb').read().splitlines())
        while '' in hosts: hosts.remove('')
        args_tmp = {}
        for cfg in set(open(sys.argv[2], 'rb').read().splitlines()):
            if 'MULTIVM_ROOT_DIR=' in cfg or 'AIO_MODE=' in cfg \
                                        or 'VM_LOGIN_USER=' in cfg:
                args_tmp.update([cfg.split("=")])
            elif 'UTIL_NAMES=' in cfg or 'SCRIPT_NAMES=' in cfg:
                k,v = cfg.split("=")
                v = v.split(',')
                args_tmp.update([[k,v]])
    except:
        print("""Usage:
        ./multivm_setup_initiate.py [hostnames filepath] [multivm.config filepath]""")
        raise

    # utils.enable_host_logger()
    SM = SetupMultiVM(hosts, args_tmp)
    # SM.delete_files()
    SM.copy_files()
    SM.make_executable()
    SM.display_files(msg="output AFTER COPYING files..")
    if sys.argv[-1] == '1':
        SM.execute_script(script_name='setup_sysbench.sh', script_args='1')
    else:
        SM.execute_script(script_name='setup_sysbench.sh')
    SM.execute_script(script_name='prepare_sysbench_tests.sh')
    # SM.execute_script(script_name='start_sysbench.sh')
