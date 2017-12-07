#!/bin/bash
#
# MEC POD IaaS Deployment Kick-Starter
# Author:Fatih E. Nar (fenar)
#
model=`juju list-models |awk '{print $1}'|grep openstack`

if [ ! -d openbaton-charm ]; then
  echo "getting openbaton-charm"
  git clone https://github.com/openbaton/juju-charm.git openbaton-charm
  sleep 10s
fi

if [ ! -d charm-neutron-api ]; then
  echo "getting calico neutorn charm"
  git clone -b ocata-support https://github.com/projectcalico/charm-neutron-api.git
  sleep 10s
fi


if [[ ${model:0:9} == "openstack" ]]; then
	juju switch openstack
     	juju deploy mec-openstack-openbaton.yaml
else
	juju add-model openstack
	juju switch openstack
     	juju deploy mec-openstack-openbaton.yaml
fi

echo "Login to the juju-gui to see status or use juju status"
juju gui --no-browser --show-credentials
