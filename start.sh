#!/bin/bash

su hadoop -s /bin/sh -c 'ssh-keygen -t ed25519 -qN "" -f $HOME/.ssh/id_ed25519'

nohup /usr/sbin/sshd 2> /dev/null

if [ -z "${MASTER_HOSTNAME}" ]; then echo "Warning: variable MASTER_HOSTNAME unset; assuming master node"; fi
if [ -z "${MASTER_HADOOP_PASSWORD}" ]; then echo "Warning: variable MASTER_HADOOP_PASSWORD unset; assuming master node"; fi
if [ "${REPLICAS}" -le 0 ]; then echo "Error: variable REPLICAS has an unvalid value; please provide a valid value"; exit 1; fi
if [ -z "${HOSTNAME}" ]; then echo "Warning: variable HOSTNAME unset; using default container hostname: $(hostname)"; HOSTNAME=$(hostname); fi
echo -n "hadoop:${PASSWORD}" | chpasswd &> /dev/null

if [ -n "$MASTER_HOSTNAME" ] && [ -n "$MASTER_HADOOP_PASSWORD" ]; then
    master_ip=$(getent hosts "$MASTER_HOSTNAME" | sed 's/\s.*//')
    while [ -z "$master_ip" ]; do sleep 1; master_ip=$(getent hosts "$MASTER_HOSTNAME" | sed 's/\s.*//'); done;
    ssh_config="Host ${HOSTNAME}
User hadoop
HostName ${HOSTNAME}"

    < /home/hadoop/.ssh/id_ed25519.pub sshpass -p "$MASTER_HADOOP_PASSWORD" ssh -o StrictHostkeyChecking=no hadoop@"$master_ip" 'cat >> /home/hadoop/.ssh/authorized_keys'
    echo "$ssh_config" | sshpass -p "$MASTER_HADOOP_PASSWORD" ssh -o StrictHostkeyChecking=no hadoop@"$master_ip" 'cat >> /home/hadoop/.ssh/config'
    hostname | sshpass -p "$MASTER_HADOOP_PASSWORD" ssh -o StrictHostkeyChecking=no hadoop@"$master_ip" 'cat >> /opt/hadoop/etc/hadoop/workers'

fi

sed -i "s/__REPLICAS__/$REPLICAS/g" /opt/hadoop/etc/hadoop/hdfs-site.xml

if [ "$1" == "-d" ]; then
  while true; do sleep 1000; done
else $1
fi