#!/bin/bash
juju config oai-enb  node_function=NGFI_RCC_IF4p5
juju config oai-enb  eth=br-eth0
juju config oai-enb  fh_if_name=br-eth0
#juju config oai-enb  downlink_frequency=2680000000L
#juju config oai-enb  uplink_frequency_offset=-120000000
#juju config oai-enb  eutra_band=7
#juju config oai-enb  N_RB_DL=50
#juju config oai-enb nb_antennas_tx=2
#juju config oai-enb nb_antennas_rx=2
#juju config oai-enb tx_gain=90
#juju config oai-enb tx_gain=120
