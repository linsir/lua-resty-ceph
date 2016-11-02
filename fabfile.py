#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : 2016-03-14 15:58:57
# @Author  : Linsir (root@linsir.org)
# @Link    : http://linsir.org
# @Version :

import os
# from fabric.api import local,cd,run,env,put
from fabric.colors import *
from fabric.api import *

APP_NAME = 'lua-resty-ceph'

import paramiko
paramiko.util.log_to_file('/tmp/paramiko.log')


# 2. using sshd_config
env.hosts = [

        'master',# master

]

env.use_ssh_config = True

prefix = '/usr/local/openresty/'

app_home = prefix + APP_NAME

def local_update():
    print(yellow("Local: Copy %s and configure..." %APP_NAME))

    if os.path.exists(app_home):
        local("sudo rm -rf %s" %app_home)

    local("sudo cp -r ../%s %s" %(APP_NAME, prefix))
    if not os.path.exists("%snginx/conf/conf.d/%s" %(prefix, APP_NAME)):
        local("sudo rm -rf %snginx/conf/conf.d/%s.conf" %(prefix, APP_NAME))
    local("sudo ln -s  %s/conf/nginx-example.conf %snginx/conf/conf.d/%s.conf" %(app_home, prefix, APP_NAME))
    restart()

def remote_update():
    print(yellow("Remote: Copy %s and configure..." %APP_NAME))
    if os.path.exists(app_home):
        run("sudo rm -rf %s" %app_home)
    app = '../' + APP_NAME
    put('app', prefix)
    with cd('%snginx/conf/conf.d/'%prefix):
        if not os.path.exists("%snginx/conf/conf.d/%s" %(prefix, APP_NAME)):
            local("sudo rm -rf %snginx/conf/conf.d/%s.conf" %(prefix, APP_NAME))
        local("sudo ln -s  %s/conf/nginx-example.conf %snginx/conf/conf.d/%s.conf" %(app_home, prefix, APP_NAME))
    print(green("openresty restarting..."))
    run('/etc/init.d/nginx restart')

def restart():
    print(green("nginx restarting..."))
    local('sudo systemctl restart nginx')
    local('curl http://127.0.0.1:8000/s3')
    # local('curl http://127.0.0.1:8000/s3?cr=y&b=haha')

def update():
    # local update
    local_update()

    # remote update
    # remote_update()

    pass
if __name__ == '__main__':
    pass