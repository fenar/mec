#!/bin/bash
# Author: Fatih E. Nar (fenar)
# Destroy Openstack Model + JUJUGVNFM Jump Host
#
set -ex
model=`juju list-models |awk '{print $1}'|grep openstack`
obnum=`hostname | cut -c 10- -`

if [[ ${model:0:9} == "openstack" ]]; then
     echo "Model:Openstack Found -> Destroy in Progress!"
     juju destroy-model "openstack" -y
else
     echo "Model:Openstack NOT Found!"
fi
