#!/bin/bash
# Author: Fatih E. NAR
# Kubernetes Deployment Kick-Starter
#

model=`juju list-models |awk '{print $1}'|grep k8s`

if [[ ${model:0:2} == "k8s" ]]; then
	juju switch k8s
     	juju deploy k8s-minimal.yaml
else
	juju add-model k8s
	juju switch k8s
     	juju deploy k8s-minimal.yaml
fi

echo "Login to the juju-gui to see status or use juju status"
juju gui --no-browser --show-credentials
