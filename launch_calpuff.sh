#!/bin/bash

TIME=$(date "+%d.%m.%Y-%H:%M:%S")

echo "$TIME starting creating VM" >> launching.log

. Ansible_envs
mkdir -p .ssh

HASH=`date --utc +%Y%m%d%H%M`; FLAVOR="m1.large"; TIMER=10

VM_NAME="calpuff_${FLAVOR/./_}_${HASH}";
KEY_PATH=.ssh/"${VM_NAME}.key";
openstack keypair create $VM_NAME >> $KEY_PATH
chmod 600 .ssh/"${VM_NAME}.key"

while true; do
   nova boot --flavor $FLAVOR\
	   --image 3bfdbb3f-e4e8-428c-b758-75a1dd366f0d\
	   --key-name $VM_NAME\
	   --security-groups d134acb2-e6bc-4c82-a294-9617fdf7bf07\
	   $VM_NAME 2>/dev/null
   for i in `seq 1 3`; do
      sec=$TIMER
      while [ $sec -ge 0 ]; do
	      echo -ne "$i attempt to start VM: $sec\033[0K\r"
              let "sec=sec-1"
              sleep 1
      done

     STATUS=`openstack server list | grep $VM_NAME | awk '{ print $6 }'`
     IP=`openstack server list | grep $VM_NAME | awk '{ split($8, v, "="); print v[2]}'`
     SYSTEM=`openstack server list | grep $VM_NAME | awk '{ print $10 }'`
    
     if [ "x$STATUS" = "xACTIVE" ]; then
	     printf "VM $VM_NAME is $STATUS, IP address $IP, system $SYSTEM\n"
      	     printf "To connect use: ssh -i $KEY_PATH ubuntu@$IP\n"
      	     echo "$TIME VM $VM_NAME is $STATUS, IP address $IP, system $SYSTEM" >> launching.log
       	     echo -e "$TIME To connect use: ssh -i $KEY_PATH ubuntu@$IP\n" >> launching.log
	           echo -e "{\n   \"hostname\":\"$VM_NAME\",\n   \"ip\":\"$IP\",\n   \"status\":\"active\"\n}" > config.json
     	     exit
     fi
   done
   printf "Trying to delete VM $VM_NAME with $STATUS status, IP address $IP, system $SYSTEM\n"
   openstack server delete `openstack server list | grep $VM_NAME | awk '{ print $2 }'`
done
