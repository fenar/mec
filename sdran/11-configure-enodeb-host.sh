#!/bin/bash
# Author: Fatih E. NAR
# 
obnum=`hostname | cut -c 10- -`

if [ -z "$1" ]; then
  NODE="node10ob$obnum"
else
  NODE=$1
fi
# configure enodeb host
configure_enodebhost() {
  export DEBIAN_FRONTEND=noninteractive
  while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)"  ]
  do
      sleep 3s
  done
  while [ ! -z "$(sudo lsof /var/lib/dpkg/lock)" ]
  do
      sleep 5s
  done
  export version=3.19.0-61
  sudo ln -s /usr/src/linux-headers-${version}*lowlatency/include/generated/autoconf.h /lib/modules/${version}*lowlatency/build/include/linux
  sudo apt-get install -y i7z cpufrequtils
  while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)"  ]
  do
      sleep 3s
  done
  while [ ! -z "$(sudo lsof /var/lib/dpkg/lock)" ]
  do
      sleep 5s
  done
  sudo bash -c 'echo GOVERNOR="performance" >> /etc/default/cpufrequtils'
  sudo update-rc.d ondemand defaults
  sudo update-rc.d ondemand disable
  sudo reboot now
}
typeset -f | ssh $NODE.maas "$(cat);configure_enodebhost" >> enodeb1.log 
