#!/bin/bash

su hadoop -s /bin/sh -c 'ssh-keygen -t ed25519 -qN "" -f $HOME/.ssh/id_ed25519'

nohup /usr/sbin/sshd 2> /dev/null

if [ -n "$MASTER_HOSTNAME" ] && [ -n "$MASTER_HADOOP_PASSWORD" ]; then
    master_ip=$(getent hosts "$MASTER_HOSTNAME" | sed 's/\s.*//')
    while [ -z "$master_ip" ]; do sleep 1; master_ip=$(getent hosts "$MASTER_HOSTNAME" | sed 's/\s.*//'); done;
    ssh_config="Host $(hostname)
User hadoop
Hostname $(hostname -i)"

    < /home/hadoop/.ssh/id_ed25519.pub sshpass -p "$MASTER_HADOOP_PASSWORD" ssh -o StrictHostkeyChecking=no hadoop@"$master_ip" 'cat >> /home/hadoop/.ssh/authorized_keys'
    echo "$ssh_config" | sshpass -p "$MASTER_HADOOP_PASSWORD" ssh -o StrictHostkeyChecking=no hadoop@"$master_ip" 'cat >> /home/hadoop/.ssh/config'
    hostname | sshpass -p "$MASTER_HADOOP_PASSWORD" ssh -o StrictHostkeyChecking=no hadoop@"$master_ip" 'cat >> /opt/hadoop/etc/hadoop/workers'

fi

if [ "$1" == "-d" ]; then
  while true; do sleep 1000; done
fi