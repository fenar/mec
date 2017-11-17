#!/bin/bash
#
# MEC POD IaaS Deployment Kick-Starter
# Author:Fatih E. Nar (fenar)
#
model=`juju list-models |awk '{print $1}'|grep openstack`

if [ ! -d openbaton-charm ]; then
  echo "creating openbaton-charm"
  git clone https://github.com/openbaton/juju-charm.git openbaton-charm
  sleep 10s
fi

if [[ ${model:0:9} == "openstack" ]]; then
	juju switch openstack
     	juju deploy openstack-klxd-calico-newton.yaml
else
	juju add-model openstack
	juju switch openstack
     	juju deploy openstack-klxd-calico-newton.yaml
fi

echo "Login to the juju-gui to see status or use juju status"
juju gui --no-browser --show-credentials
