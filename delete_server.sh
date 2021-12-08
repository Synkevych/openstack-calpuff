#!/bin/bash

if [ $# -ne 1 ]; then echo "Usage: $0 VM_name"; exit 1; fi

VM_NAME=$1

. WRF-UNG.rc # load openstack environment variables

rm ".ssh/${VM_NAME}.key"
echo "SSH key for $VM_NAME deleted" >> vm_launching.log

openstack keypair delete ${VM_NAME}
echo "Openstak keypair for $VM_NAME deleted" >> vm_launching.log

openstack server delete ${VM_NAME}
echo -e "Openstack server $VM_NAME deleted\n" >> vm_launching.log
