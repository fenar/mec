#!/bin/bash
#
# SDRAN Deployment Kick-Starter
# Author:Fatih E. Nar (fenar)
#
model=`juju list-models |awk '{print $1}'|grep sdran`

#if [ ! -d influxdb-charm ]; then
#  echo "creating openbaton-charm"
#  git clone https://github.com/ChrisMacNaughton/charm-influx.git influxdb-charm
#  sleep 10s
#fi

#if [ ! -d telegraf-charm ]; then
#  echo "creating openbaton-charm"
#  git clone https://git.launchpad.net/telegraf-charm telegraf-charm
#  sleep 10s
#fi

#if [ ! -d grafana-charm ]; then
#  echo "creating openbaton-charm"
#  git clone https://git.launchpad.net/grafana-charm grafana-charm
#  sleep 10s
#fi

# openstack-ocata-openbaton-sriov.yaml
echo "Available SDRAN Deployment Options:"
echo "(1) -> IoT Band4 Bundle with InfluxDB + Telegraf + Grafana"
echo "(2) -> ..."
echo "(3) -> ..."

echo "Enter Your Choice: "
read -n 2 r
if [ "$r" = "1" ] ; then
        echo "Deploying IOT Band4 with ITG"
        if [[ ${model:0:5} == "sdran" ]]; then
                juju switch sdran
                juju deploy Band4-ITG.yaml
        else
                juju add-model sdran
                juju switch sdran
                juju deploy Band4-ITG.yaml
        fi
else
	echo "ERROR: Unimplemented Option!"
fi
echo "Login to the juju-gui to see status or use juju status"
juju gui --no-browser --show-credentials
