#!/bin/bash

if [ $# -ne 1 ]; then echo "Usage: $0 hostname or VM name"; exit 1; fi

VM_NAME=$1 # or VM_NAME=$(cat config.json | grep $VM_NAME | cut -d : -f2 | awk -F\" '{print $2}')
STATUS=`openstack server list | grep $VM_NAME | awk '{ print $6 }'`

set -e # exit on the first error

. ENV # load openstack environment variables
TIME=$(date "+%d.%m.%y-%H:%M:%S")

if test -z "$STATUS"; then
        echo "$VM_NAME VM not found, canceling\n"
        echo -e "$TIME $VM_NAME VM not found, canceling\n" >> launching.log
        exit
fi

echo "VM $VM_NAME found, starting removing"

openstack server delete ${VM_NAME}
sleep 10 & wait
echo -e "$TIME Openstack server $VM_NAME deleted\n" >> launching.log

openstack keypair delete ${VM_NAME}
echo "$TIME Openstak keypair for $VM_NAME deleted" >> launching.log

rm ".ssh/${VM_NAME}.key"
echo "$TIME SSH key for $VM_NAME deleted" >> launching.log

echo -e "{\n   \"hostname\":\"$VM_NAME\",\n   \"status\":\"deleted\"\n}" > config.json

echo "VM $VM_NAME and it keys successfully removed"
