#!/bin/bash
# Author: Fatih E. Nar (fenar)
# Destroy Kubernetes
#
set -ex
model=`juju list-models |awk '{print $1}'|grep k8s`
if [[ ${model:0:3} == "k8s" ]]; then
     echo "Model:k8s Found -> Destroy in Progress!"
     juju destroy-model "k8s" -y
else
     echo "Model:k8s NOT Found!"
fi
