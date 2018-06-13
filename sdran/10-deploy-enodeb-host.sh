#!/bin/bash
# Author: Fatih E. NAR
# 
# Please Set following Global Kernel Paramaters on MaaS:
#  -> net.ifnames=0 apparmor=0 intel_pstate=disable intel_idle.max_cstate=0 processor.max_cstate=1 idle=poll
# Ref: https://gitlab.eurecom.fr/oai/openairinterface5g/wikis/OpenAirKernelMainSetup
#
#obnum=`hostname | cut -c 10- -`
obnum=140

if [ -f "/home/ubuntu/.ssh/known_hosts" ]; then
  sudo rm /home/ubuntu/.ssh/known_hosts
fi

if [ -z "$1" ]; then
  NODE="node10ob140"
else
  NODE=$1
fi

# deploy node on maas
maas admin machines allocate name=$NODE
NODE_ID=$(maas admin nodes read hostname=$NODE | python -c "import sys, json;print json.load(sys.stdin)[0]['system_id']")
maas admin machine deploy "$NODE_ID" distro_series=trusty hwe_kernel=hwe-t

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

# deploy enodeb host
deploy_enodebhost() {
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
    sudo -E apt-get install -y linux-image-3.19.0-61-lowlatency linux-headers-3.19.0-61-lowlatency
    while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)" ]
    do
        sleep 3s
    done
    while [ ! -z "$(sudo lsof /var/lib/dpkg/lock)" ]
    do
        sleep 5s
    done
    sudo reboot now
}
typeset -f | ssh $NODE.maas "$(cat);deploy_enodebhost" >> enodeb0.log
