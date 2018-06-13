#!/bin/bash
# InfluxDB + Grafana
# Author: Fatih E. NAR
# 
#
set -ex

obnum=`hostname | cut -c 10- -`

if [ -f "/home/ubuntu/.ssh/known_hosts" ]; then
  sudo rm /home/ubuntu/.ssh/known_hosts
fi

if [ -z "$1" ]; then
  NODE="node09ob140"
else
  NODE=$1
fi

# deploy node on maas
maas admin machines allocate name=$NODE
NODE_ID=$(maas admin nodes read hostname=$NODE | python -c "import sys, json;print json.load(sys.stdin)[0]['system_id']")
maas admin machine deploy "$NODE_ID"

# wait till the machine is up
while [ "$(maas admin nodes read hostname=$NODE | python -c "import sys, json;print json.load(sys.stdin)[0]['status_name']")" != "Deployed" ]
do
    echo "Waiting for ready on $NODE..."
    sleep 10s
done

# check if ssh is up
while ! ssh $NODE.maas echo
do
    echo "Waiting for sshd on $NODE..."
    sleep 10s
done

# copy over the used ssh-keypair
scp ~/.ssh/id_rsa ~/.ssh/id_rsa.pub $NODE.maas:.ssh/

# install cicd
install_ig() {
    set -ex
    export DEBIAN_FRONTEND=noninteractive

    while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)"  ]
    do
        sleep 3s
    done
    while [ ! -z "$(sudo lsof /var/lib/dpkg/lock)" ]
    do
        sleep 5s
    done
    sudo apt-get update

    while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)" ]
    do
        sleep 3s
    done
    while [ ! -z "$(sudo lsof /var/lib/dpkg/lock)" ]
    do
        sleep 5s
    done

    #instrall influxdb
    curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
    source /etc/lsb-release
    sudo -S true
    echo "deb https://repos.influxdata.com/${DISTRIB_ID,,} ${DISTRIB_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
    sudo apt-get update
    while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)"  ]
    do
        echo "Waiting for dpkg/apt lock..."
        sleep 3s
    done
    while [ ! -z "$(sudo lsof /var/lib/dpkg/lock)" ]
    do
        echo "Waiting for dpkg lock..."
        sleep 5s
    done

    sudo apt-get install influxdb
    sleep 10s
    sudo service influxdb start
    sudo systemctl enable influxdb.service
    sleep 5s

    #install grafana
    echo "deb https://packagecloud.io/grafana/stable/debian/ jessie main" | sudo tee /etc/apt/sources.list.d/grafana.list
    curl https://packagecloud.io/gpg.key | sudo apt-key add -
    sudo apt-get update
    while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)"  ]
    do
        echo "Waiting for dpkg/apt lock..."
        sleep 3s
    done
    while [ ! -z "$(sudo lsof /var/lib/dpkg/lock)" ]
    do
        echo "Waiting for dpkg lock..."
        sleep 5s
    done
    sudo apt-get install grafana

    sudo service grafana-server start
    sudo systemctl enable grafana-server.service
    influx -execute 'CREATE DATABASE iot_weather'
    influx -execute 'SHOW DATABASES'
}
typeset -f | ssh $NODE.maas "$(cat);install_ig" >> IG.log
