#!/bin/bash
# Author: Fatih E. NAR
# 
obnum=`hostname | cut -c 10- -`

if [ -z "$1" ]; then
  NODE="node10ob$obnum"
else
  NODE=$1
fi
# install oai enodeb
install_oaienodeb() {
  export DEBIAN_FRONTEND=noninteractive
  while [ ! -z "$(sudo lsof /var/lib/apt/lists/lock)"  ]
  do
      sleep 3s
  done
  while [ ! -z "$(sudo lsof /var/lib/dpkg/lock)" ]
  do
      sleep 5s
  done
  sudo apt-get install -y git
  sudo chown -R ubuntu:ubuntu /srv
  cd /srv
  git config --global user.name "fenar"
  git config --global user.email "fenar@yahoo.com"
  echo -n | openssl s_client -showcerts -connect gitlab.eurecom.fr:443 2>/dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | sudo tee -a /etc/ssl/certs/ca-certificates.crt
  git config --global http.sslverify false
  git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git openairinterface
  cd openairinterface
  source oaienv
  cd cmake_targets
  ./build_oai -I --eNB -x --install-system-files -w USRP
  echo "Edit ~/openairinterface/targets/PROJECTS/GENERIC-LTE-EPC/CONF/enb.band7.tm1.usrpb210.conf to match with your Networking"
  echo "Samsung Galaxy S5 SM-G900A supports following Bands: 1,2,3,4,5,7,17"
  echo "Execute: $ source /srv/openairinterface5g/oaienv"
  echo "Execute: $ ./srv/openairinterface/cmake_targets/lte_build_oai/build/lte-softmodem -O $OPENAIR_DIR/targets/PROJECTS/GENERIC-LTE-EPC/CONF/enb.band7.tm1.usrpb210.conf"
}
typeset -f | ssh $NODE.maas "$(cat);install_oaienodeb" >> enodeb3.log 
