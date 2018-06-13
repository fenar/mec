#!/bin/bash
# OPNFV CI/CD Machine Builder Part-IV
# Author: Fatih E. NAR
# Ref: https://wiki.opnfv.org/display/INF/How+to+Setup+CI+to+Run+OPNFV+Deployment+and+Testing
#
set -ex
email="user@email.com"
name="username"

# configure jumphost for jenkins user
cj() {
    set -ex
    export DEBIAN_FRONTEND=noninteractive

    while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)"  ]
    do
        echo "Waiting for dpkg/apt lock..."
        sleep 3s
    done
    mkdir joid_config
    mkdir ~/.ssh
    chmod 700 ~/.ssh
    cd ~/.ssh
    echo "/home/jenkins/.ssh/id_rsa" | ssh-keygen -t rsa
    touch ~/.ssh/authorized_keys
    chmod 600 ~/.ssh/authorized_keys
    cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
    mkdir ~/slave_root
    git config --global user.email $email
    git config --global user.name $name
    sudo usermod -aG docker jenkins
    echo 'jenkins ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee -a' visudo
}
typeset -f | ssh jenkins@localhost "$(cat);cj"
