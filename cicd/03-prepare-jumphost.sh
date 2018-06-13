#!/bin/bash
# OPNFV CI/CD Machine Builder Part-III
# Author: Fatih E. NAR
# Ref: https://wiki.opnfv.org/display/INF/How+to+Setup+CI+to+Run+OPNFV+Deployment+and+Testing
#
set -ex
export DEBIAN_FRONTEND=noninteractive
sudo adduser jenkins --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password
echo "jenkins:jenkins" | sudo chpasswd
sudo usermod -aG sudo jenkins

while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)"  ]
do
    echo "Waiting for dpkg/apt lock..."
    sleep 3s
done
sudo apt-get update
while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)" ]
do
    echo "Waiting for dpkg/apt lock..."
    sleep 3s
done
sudo -E apt-get install -y git python openjdk-8-jre sshpass curl
while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)" ]
do
    echo "Waiting for dpkg/apt lock..."
    sleep 3s
done
curl -sSL https://get.docker.com/ | sudo sh
sleep 10s
echo "Time to Logout and Login with jenkins useer and run; docker run hello-world "
