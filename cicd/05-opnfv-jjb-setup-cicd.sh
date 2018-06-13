#!/bin/bash
# OPNFV CI/CD Machine Builder Part-V
# Author: Fatih E. NAR
# Ref: https://wiki.opnfv.org/display/INF/How+to+Setup+CI+to+Run+OPNFV+Deployment+and+Testing
#
obnum=`hostname | cut -c 10- -`
NODE="node00vm0ob$obnum"
# install cicd
jjb() {
	mkdir ~/repos && cd ~/repos
	git clone https://gerrit.opnfv.org/gerrit/releng.git && cd releng
	git fetch https://gerrit.opnfv.org/gerrit/releng refs/changes/95/35895/1 && git checkout FETCH_HEAD
	git checkout -b test-jjb-setup
	cd jjb/releng
	jenkins-jobs update test-jjb-setup.yml
        cd ~/repos
        git clone https://gerrit.opnfv.org/gerrit/yardstick.git && cd yardstick
        git checkout master

}
typeset -f | ssh jenkins@$NODE.maas "$(cat);jjb"
