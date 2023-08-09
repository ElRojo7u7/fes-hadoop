#!/bin/bash

NC='\033[0m'              # No Color
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Cyan='\033[0;36m'         # Cyan


su hadoop -s /bin/sh -c 'ssh-keygen -t ed25519 -qN "" -f $HOME/.ssh/id_ed25519'
nohup /usr/sbin/sshd 2> /dev/null

if [ -z "${MASTER_HOSTNAME}" ]; then echo -e "${Red}[!] Error${NC}: variable MASTER_HOSTNAME expected some value"; exit 1; fi
if [ -z "${MASTER_HADOOP_PASSWORD}" ]; then echo -e "${Yellow}[!] Warning${NC}: variable MASTER_HADOOP_PASSWORD unset; assuming master node"; fi
if [ "${REPLICAS}" -le 0 ]; then echo -e "${Red}[!] Error${NC}: variable REPLICAS has an unvalid value; please provide a valid value"; exit 1; fi
if [ -z "${HOSTNAME}" ]; then echo -e "${Yellow}[!] Warning${NC}: variable HOSTNAME unset; using default container hostname: $(hostname)"; HOSTNAME=$(hostname); fi
echo -n "hadoop:${PASSWORD}" | chpasswd &> /dev/null

if [ -n "$MASTER_HOSTNAME" ] && [ -n "$MASTER_HADOOP_PASSWORD" ]; then
    declare -i attempts=0
    (echo '' > /dev/tcp/"${MASTER_HOSTNAME}"/22) 2>/dev/null
    while [ $? -eq 1 ]; do
      let attempts+=1
      if [ "${attempts}" -gt 40 ]; then
        echo -e "${Red}[!] Error${NC}: Attempted ${attempts} times to connect to ${MASTER_HOSTNAME} at port 22 with no success; Exiting"
        exit 1
      fi 
      sleep 2; (echo '' > /dev/tcp/"${MASTER_HOSTNAME}"/22) 2>/dev/null;
    done
    ssh_config="Host ${HOSTNAME}
User hadoop
HostName ${HOSTNAME}"
    {
      < /home/hadoop/.ssh/id_ed25519.pub sshpass -p "$MASTER_HADOOP_PASSWORD" ssh -o StrictHostkeyChecking=no hadoop@"${MASTER_HOSTNAME}" 'cat >> /home/hadoop/.ssh/authorized_keys'
      echo -e "${Cyan}[+]${NC} Succesfully suplied public key to master"
      echo "$ssh_config" | sshpass -p "$MASTER_HADOOP_PASSWORD" ssh -o StrictHostkeyChecking=no hadoop@"${MASTER_HOSTNAME}" 'cat >> /home/hadoop/.ssh/config'
      echo -e "${Cyan}[+]${NC} ${HOSTNAME} added to master's ~/.ssh/config"
      echo "${HOSTNAME}" | sshpass -p "$MASTER_HADOOP_PASSWORD" ssh -o StrictHostkeyChecking=no hadoop@"${MASTER_HOSTNAME}" 'cat >> /opt/hadoop/etc/hadoop/workers'
      echo -e "${Cyan}[+]${NC} ${HOSTNAME} added to master's /opt/hadoop/etc/hadoop/workers"
    } || {
      echo -e "${Red}[!] Error${NC}: Unable to connect to master via ssh, did you provide the correct password?"
      exit 1
    }

fi

sed -i "s|__REPLICAS__|${REPLICAS}|g" /opt/hadoop/etc/hadoop/hdfs-site.xml
echo -e "${Cyan}[+]${NC} Applied replicas to hdfs-site.xml"
sed -i "s|__MASTER_HOSTNAME__|${MASTER_HOSTNAME}|g" /opt/hadoop/etc/hadoop/core-site.xml
echo -e "${Cyan}[+]${NC} Applied MASTER_HOSTNAME to core-site.xml"

echo -e "${Green}[+]${NC} Node: ${HOSTNAME} is ready"

while getopts "db" o; do
  case "${o}" in
    d) while true; do sleep 1000; done;;
    b) bash;;
    *) echo -e "${Red}[!] Error${NC}: flag '${o}' not valid";exit 1;;
  esac
done