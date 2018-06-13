# sdran
Software Defined Radio Related Work <br>
Ref-URL: https://gitlab.eurecom.fr/oai/openairinterface5g/wikis/HowToConnectCOTSUEwithOAIeNB

#Compile
cd ~/openairinterface <br>
source oaienv <br>
cd cmake_targets <br>
./build_oai -I -g --eNB -x --install-system-files -w USRP  <br>

#Edit
/srv/openairinterface/targets/PROJECTS/GENERIC-LTE-EPC/CONF/enb.band7.tm1.usrpb210.conf
```sh
// Tracking area code, 0x0000 and 0xfffe are reserved values

tracking_area_code = "1";

mobile_country_code = "208";

mobile_network_code = "95";

////////// Physical parameters:

...

////////// MME parameters:

mme_ip_address = ( {ipv4 = "192.170.0.1";

ipv6="192:168:30::17";

active="yes";

NETWORK_INTERFACES :

{

ENB_INTERFACE_NAME_FOR_S1_MME = "eth0:3";

ENB_IPV4_ADDRESS_FOR_S1_MME = "192.170.0.2/24";

ENB_INTERFACE_NAME_FOR_S1U = "eth0:4";

ENB_IPV4_ADDRESS_FOR_S1U = "192.170.1.2/24";

ENB_PORT_FOR_S1U = 2152; # Spec 2152

};
```

#Execute
cd ~/openairinterface <br>
source oaienv <br>
./cmake_targets/build_oai -w USRP -x -c --eNB <br>
cd cmake_targets/lte_build_oai/build <br>
sudo -E ./lte-softmodem -O $OPENAIR_DIR/targets/PROJECTS/GENERIC-LTE-EPC/CONF/enb.band7.tm1.usrpb210.conf -d <br>
sudo -E ./lte-softmodem -h #(to see help options) <br>

NOTES:
(a) protobuf_c broken in main, workaround described in https://gitlab.eurecom.fr/oai/openairinterface5g/issues/259
