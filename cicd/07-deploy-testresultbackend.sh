#!/bin/bash
# Author: Fatih E. NAR
# 
set -ex

obnum=`hostname | cut -c 10- -`
NODE="node00vm0ob$obnum"

# install cicd
install_tools() {
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
    #
    #Name: opnfv
    # Type: InfluxDB 0.9.x
    # Url: http://localhost:8086/
    # Database: jenkins_data
    # User: admin
    # Password: admin
    influx -execute 'CREATE DATABASE functest'
    influx -execute 'CREATE DATABASE yardstick'
    influx -execute 'SHOW DATABASES'
}
typeset -f | ssh jenkins@$NODE.maas "$(cat);install_tools"
