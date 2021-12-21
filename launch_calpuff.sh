#!/bin/bash

TIME=$(date "+%d.%m.%Y-%H:%M:%S")

. Ansible_envs
mkdir -p .ssh

HASH=`date --utc +%d%m%Y%H%M`;
FLAVOR="m1.large";
IMAGE="3bfdbb3f-e4e8-428c-b758-75a1dd366f0d";
TIMER=10;

HOSTNAME="calpuff_${FLAVOR/./_}_${HASH}";
KEY_PATH=.ssh/"${HOSTNAME}.key";
openstack keypair create $HOSTNAME >> $KEY_PATH
chmod 600 .ssh/"${HOSTNAME}.key"

echo "$TIME The beginning of the creation of VM $HOSTNAME" >> launching.log

while true; do
   nova boot --flavor $FLAVOR\
	   --image $IMAGE\
	   --key-name $HOSTNAME\
	   --security-groups d134acb2-e6bc-4c82-a294-9617fdf7bf07\
	   $HOSTNAME 2>/dev/null
   for i in `seq 1 3`; do
      sec=$TIMER
      while [ $sec -ge 0 ]; do
	      echo -ne "$i attempt to start VM: $sec\033[0K\r"
              let "sec=sec-1"
              sleep 1
      done

     STATUS=`openstack server list | grep $HOSTNAME | awk '{ print $6 }'`
     IP=`openstack server list | grep $HOSTNAME | awk '{ split($8, v, "="); print v[2]}'`
     SYSTEM=`openstack server list | grep $HOSTNAME | awk '{ print $10 }'`

     if [ "x$STATUS" = "xACTIVE" ]; then
	     printf "VM $HOSTNAME has status $STATUS, IP address $IP, image $SYSTEM\n"
      	     printf "To connect use: ssh -i $KEY_PATH ubuntu@$IP\n"
      	     echo "$TIME VM $HOSTNAME is $STATUS, IP address $IP, image $SYSTEM" >> launching.log
       	     echo -e "$TIME To connect use: ssh -i $KEY_PATH ubuntu@$IP\n" >> launching.log
	           echo -e "{\n   \"hostname\":\"$HOSTNAME\",\n   \"ip\":\"$IP\",\n   \"status\":\"active\"\n}" > config.json
     	     exit
     fi
   done
   echo -e "{\n   \"hostname\":\"$HOSTNAME\",\n   \"ip\":\"$IP\",\n   \"status\":\"error\"\n}" > config.json
   printf "Launching $HOSTNAME failed with status: $STATUS"
   echo -e "$TIME Launching $HOSTNAME failed with status: $STATUS\n" >> launching.log
   exit
done
