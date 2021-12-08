#!/bin/bash

set -e # exit on the first error
. WRF-UNG.rc

HASH=`date --utc +%Y%m%d%H%M`; FLAVOR="m1.large"; TIMER=60

VM_NAME="calpuff_${FLAVOR/./_}_${HASH}";
FILE_PATH=.ssh/"${VM_NAME}.key";
openstack keypair create $VM_NAME >> $FILE_PATH
chmod 600 .ssh/"${VM_NAME}.key"

# copy keys for rodos user
RODOS_PATH=$(pwd)

cp .ssh/"${VM_NAME}.key" $RODOS_PATH
printf "copy $VM_NAME ssh key to $RODOS_PATH\n"

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
     SYSTEM=`openstack server list | grep $VM_NAME | awk '{ print $10 $11 }'`
    
     if [ "x$STATUS" = "xACTIVE" ]; then
	     printf "VM $VM_NAME is $STATUS, IP address $IP, system $SYSTEM\n"
      	     printf "To connect use: ssh -i $FILE_PATH ubuntu@$IP\n"
      	     echo -e "VM $VM_NAME is $STATUS, IP address $IP, system $SYSTEM\n" >> launching.log
       	     echo "To connect use: ssh -i $FILE_PATH ubuntu@$IP" >> launching.log
	     echo -e "{\n   \"ip\":\"$IP\",\n   \"key\":\"$VM_NAME\",\n   \"status\":\"active\"\n}" > "$RODOS_PATH/config.json"
             printf "Copied config.json to $RODOS_PATH\n"
     	     exit
     fi
   done
   printf "Trying to delete VM $VM_NAME with $STATUS status, IP address $IP, system $SYSTEM\n"
   openstack server delete `openstack server list | grep $VM_NAME | awk '{ print $2 }'`
done
