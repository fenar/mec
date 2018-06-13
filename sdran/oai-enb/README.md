# Overview

The E-UTRAN handles the radio communications between the mobile and the evolved packet core and just has one component, the evolved base stations, called eNodeB or eNB. Each eNB is a base station that controls the mobiles in one or more cells.

This charm aims to deploy an LTE base station of OpenAirInterface (OAI) wireless technology platform, 
an opensource software-based implementation of the LTE system
developed by EURECOM. It is written in the C programming language.


# Usage

This charm is available in the Juju Charm Store, to deploy you'll need a working 
Juju installation, and a successful bootstrap. This charm need to be deployed 
with other charms to get a open LTE network made up of LTE base station and core
network. MySQL charm should be related to OAI-HSS. The latter should be related
to OAI-EPC charm that should be related to this charm.


Please refer to the
[Juju Getting Started](https://juju.ubuntu.com/docs/getting-started.html)
documentation before continuing.

Using this charm together with your core network(OAI-EPC and OAI-HSS charms) forces you use manual provider,
local provider, your private openstack cloud or MAAS, because the OAI-ENB charm requires to be deployed on 
a machine with a hosted software radio frontend interface(exmimo2 or usrp) to provide the radio coverage. 
In general you need to use a machine where the following CPU flags are supported: ssse3, avx2,sse4.2,sse4.1.


## Local provider


Once bootstrapped, deploy the MySQL charm then the oai-hss charm:

    juju deploy mysql
    juju deploy oai-hss

Have a look at what's going on:

    watch juju status --format tabular

Juju creates two KVM nodes with a oai-hss unit and a mysql unit.

Add a relation between the two:

    juju add-relation oai-hss mysql

You can deploy in two lxc nodes within a single kvm by refering to the
[LXC Containers within a KVM Guest](https://jujucharms.com/docs/devel/config-KVM#lxc-containers-within-a-kvm-guest) 

To have a look at the hss output:
    
    juju ssh oai-hss/0
    cat /srv/enb.out  

Then you could add OAI-EPC charm to complete the LTE core network:

    juju deploy --constraints "cpu-cores=2 mem=1G" oai-epc

You need to use the "constraints" option in order to tune the machine based on the computational
power you want for this service.

Now you have one unit of oai-epc service named "oai-epc/0" and a unit of oai-hss service named "oai-hss/0".

Add a relation between oai-epc and oai-hss:

    juju add-relation oai-epc oai-hss

Have a look at the OAI-EPC output and see if it is connected to OAI-HSS service:
    
    juju ssh oai-epc/0
    cat /srv/enb.out  

The order of deployment doesn't matter, so you can deploy all the charms you want to and then add all the relations afterwards. The order in which relations are added can be whatever you want, the OAI software will start in the 
right order anyway.

Then to complete the LTE network you will have the chance to deploy your LTE base station. For the OAI-ENB charm
you need to add manually a machine to the local environment, otherwise the local provider would create a new
machine and would immidiately deploy the charm on that without giving the chance to change the machine feature.

    juju add-machine --constraints "mem=4G cpu-cores=3"

This constraints are ther minimum for this service to work. Through Juju you can't expose the host CPU flags
to the kVM just created(add-machine). So you need to manually expose them through other tools like virtual manager.
Once you have done this, you also need to do a passthrough of the radio frontend hardware from host to KVM.

you can deploy the charm:

    juju deploy --to N oai-enb

Wheren N is number of the machine you have just created that you can find by means the command "juju status".

## Manual environment

Deployment example: all KVM nodes in one physical machine(juju bootstrap node).

Once bootstrapped, deploy the MySQL charm then the oai-hss charm:

    juju deploy --to kvm:0 mysql
    juju deploy --to kvm:0 oai-hss

Juju creates two KVM nodes with a unit of oai-hss and a unit of mysql.

Add a relation between the two:

    juju add-relation oai-hss mysql

To have a look at the hss unit output:
    
    juju ssh hss/0
    cat /srv/enb.out

Then you could add a unit of EPC charm to complete the LTE core network:

    juju deploy --to kvm:0 oai-epc

Add a relation between the oai-epc service unit and oai-hss service unit:

    juju add-relation oai-epc oai-hss

To have a look at the oai-epc output and see if it is connected to oai-hss unit:
    
    juju ssh oai-epc/0
    cat /srv/enb.out

Then to complete the LTE network you will have the chance to deploy your LTE base station. For the OAI-ENB charm
you need to add manually a machine to the manual environment, otherwise the local provider would create a new
machine and would immidiately deploy the charm on that without giving the chance to change the machine feature.

    juju add-machine --to kvm:0

Through Juju you can't expose the host CPU flags to the kVM just created(add-machine). So you need to manually expose them through other tools like virtual manager.
Once you have done this, you also need to do a passthrough of the radio frontend hardware from host to KVM.
Then you change the virtual machine features to have 3 CPUs and 4G of memory again through virtual manager.

Now you can deploy the charm:

    juju deploy --to 0/kvm/N oai-enb

Wheren N is number of the machine you have just created.
Add a relation between the oai-epc service unit and oai-hss service unit:

    juju add-relation oai-enb oai-epc

### Group of services

Consider to deploy directly against physical machines because the KVM that juju creates 
are behind a NAT bridge. In fact if you want to use kvm, you should create some kvm containes
outside of juju with proper networking and add-machine to juju.


    juju deploy --to kvm:1 mysql
    juju deploy --to 1 oai-hss

    
    juju deploy --to 2 oai-epc epc-rome
    juju deploy --to 3 oai-epc epc-nice
    juju deploy --to 4 oai-epc epc-torino


    juju add-relation oai-hss mysql
    juju add-relation epc-rome oai-hss
    juju add-relation epc-nice oai-hss
    juju add-relation epc-torino oai-hss

    juju deploy --to 5 oai-enb oai-enb-rome0
    juju deploy --to 6 oai-enb oai-enb-rome1
    juju deploy --to 7 oai-enb oai-enb-rome2

    juju deploy --to 5 oai-enb oai-enb-nice0
    juju deploy --to 6 oai-enb oai-enb-nice1
    juju deploy --to 7 oai-enb oai-enb-nice2
    
    juju add-relation epc-rome oai-enb-rome0
    juju add-relation epc-rome oai-enb-rome1
    juju add-relation epc-rome oai-enb-rome2

    juju add-relation epc-nice oai-enb-nice0
    juju add-relation epc-nice oai-enb-nice1
    juju add-relation epc-nice oai-enb-nice2



## Scale Out Usage

If you need to scale out your epc-rome service(for instance), you can add another service from the oai-epc
charm in "Rome" datacenter:
by typing:

    juju deploy --to 8 oai-epc epc-rome1
    
    juju add-relation epc-rome1 oai-enb-rome0
    juju add-relation epc-rome1 oai-enb-rome1
    juju add-relation epc-rome1 oai-enb-rome2

Now the eNBs in Rome will be related to two epc services in order to have the choice about where to
attach a specific UE.

## Known Limitations and Issues

### Important

 * **Removing relation between hss service and mysql service(consider the simple case in which we have only one service of hss charm and for this service we have deployed only one unit. Same for mysql service)**


    juju remove-relation oai-hss mysql

If you need to remove the relation between hss service and mysql service, HSS sofware
is stopped and so EPC running software fails to connect to HSS that is put in a zombie state. For this reason db-relation-departed hook execution triggers hss-relation-changed hook on oai-epc side that stops EPC sofware.
Also all the oai-enb services attached to that specific oai-epc will be advertised in order to stop their software.
As soon as you re-add a relation with a mysql service, HSS process will be restarted and the db-relation-changed hook execution will trigger hss-relation-changed hook in each EPC unit that will start EPC sofware again.
Hss-relation-changed triggers also the epc-relation-changed hook(oai-enb side) to in order to restart the 
eNB software.

   Be aware that the new database inside mysql unit doesn't have the old data, but simply the mme entries to allow the MMEs to connect to hss__

 * **Removing relation between epc service and hss service**

    juju remove-relation epc-rome oai-hss

The software of the oai-epc service will be stopped and oai-hss will be removing the MMEs 
from the database. oai-hss software remains running because you might 
have more oai-epc services(epc-rome, epc-turin, epc-nice) using 
the same oai-hss service so we don't want to break the connections.
Of course all the oai-enb services related to that oai-epc service (epc-rome) will be advertise to stop
their software.
As soon as you re-add it, epc-rome service will start its software, reconnecting to the oai-hss software
and all the eNBs services related to it will be advertise to re-run their software in order to setup
again the S1 link.

# Configuration

You can tweak various options for your oai-enb deployment:

 * target_hardware - 

 * eth - 

 * TAC - 

 * enb_id - 

 * enb_name - 

 * mme-statistic-timer - 

 * frame_type - 

 * tdd_config -

 * tdd_config_s - 

 * eutra_band - 

 * downlink_frequency - 

 * uplink_frequency_offset - 

 * N_RB_DL - 

 * nb_antennas_tx - 

 * nb_antennas_rx - 

 * tx_gain - 

 * rx_gain - 

Each option can be changed before deployment by providing a "myconfig.yaml" to your deployment command with the value you want each option to take. For what concern the enb-name and the enb-ID you are obliged to change them
for oai-enb service deployment otherwise the connection towards the MME(oai-epc software) is going to fail:


    juju deploy --to 5 --config /home/myconfig.yaml oai-enb oai-enb-rome0


Each option can be changed also at runtime by running:

    juju set <service> <option>=<value>


# Contact Information

## MOSAIC-5G
- [MOSAIC-5G website]()
- [More info]()

## OpenairInterface

- [OpenAirInterface website](http://www.openairinterface.org/)
- [More info](contact@openairinterface.org)

# TODOs

 * Double-check what exactly needs permissions. At the moment all runs under root.
 * Change upstart script in a way that if the machine is rebooted the oai-enb process is automatically restarted if it was running during the shutdown procedure.
