#!/bin/bash
#Author: Fatih E. NAR
set -eaux
obnum=`hostname | cut -c 10- -`
time juju bootstrap --config bootstrap-timeout=1200 --to v4n-node01ob160.maas --show-log v4n${obnum}-maas  maas-v4n${obnum}-controller
echo "..."
juju gui --no-browser --show-credentials
