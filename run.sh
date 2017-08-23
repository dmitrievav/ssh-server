#!/bin/bash

mkdir /root/.ssh
echo $SSH_PUB_KEY > /root/.ssh/authorized_keys
chmod 400 /root/.ssh/authorized_keys

/usr/sbin/sshd -D