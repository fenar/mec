#!/bin/bash
# OPNFV CI/CD Machine Builder Part-II
# Author: Fatih E. NAR
# Ref: https://wiki.opnfv.org/display/INF/How+to+Setup+CI+to+Run+OPNFV+Deployment+and+Testing
# 
set -ex

obnum=`hostname | cut -c 10- -`
NODE="node00vm0ob$obnum"

# check if ssh is up
while ! ssh $NODE.maas echo
do
    echo "Waiting for sshd on $NODE..."
    sleep 10s
done

scp jenkinsplugin.sh jenkinspluginlist.txt jenkins_jobs.ini yardstick.conf $NODE.maas:./

# install cicd
install_plugins() {
    set -ex
    export DEBIAN_FRONTEND=noninteractive

    while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)" ]
    do
        echo "Waiting for apt lock..."
        sleep 3s
    done
    sudo mkdir /etc/jenkins_jobs
    sudo mv jenkins_jobs.ini /etc/jenkins_jobs/
    echo "Please Update Admin API Key in /etc/jenkins_jobs/jenkins_jobs.ini!!!"
    sudo mkdir /etc/yardstick
    sudo mv yardstick.conf /etc/yardstick/
    sudo ./jenkinsplugin.sh --plugins jenkinspluginlist.txt --plugindir /var/lib/jenkins/plugins
    sudo service jenkins restart
}
typeset -f | ssh $NODE.maas "$(cat);install_plugins"
