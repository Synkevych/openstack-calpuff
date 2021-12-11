#!/bin/bash

set -e # exit on the first error

. /home/roman/WRF-UNG.rc # load openstack environment variables
TIME=$(date "+%d.%m.%y-%H:%M:%S")

VM_NAME=$(cat config.json | grep hostname | cut -d : -f2 | awk -F\" '{print $2}')

rm ".ssh/${VM_NAME}.key"
echo "$TIME SSH key for $VM_NAME deleted" >> launching.log

openstack keypair delete ${VM_NAME}
echo "$TIME Openstak keypair for $VM_NAME deleted" >> launching.log

openstack server delete ${VM_NAME}
echo -e "$TIME Openstack server $VM_NAME deleted\n" >> launching.log

sed -i 's/active/deleted/g' config.json
