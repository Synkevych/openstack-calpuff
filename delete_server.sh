#!/bin/bash

if [ $# -ne 1 ]; then echo "Usage: $0 VM_name"; exit 1; fi

VM_NAME=$1

rm ".ssh/${VM_NAME}.key"

. WRF-UNG.rc

openstack keypair delete ${VM_NAME}

openstack server delete ${VM_NAME}
