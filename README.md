# Prep-Step Before Deployment: MAAS & JUJU SETUP
```sh
ubuntu@OrangeBox140:~/.local/share/juju$ cat clouds.yaml
clouds:
  v4n140-maas:
    type: maas
    auth-types: [oauth1]
    endpoint: http://172.27.140.1/MAAS/
ubuntu@OrangeBox140:~/.local/share/juju$ cat credentials.yaml 
credentials:
  v4n140-maas:
    maas:
      auth-type: oauth1
      maas-oauth: Wx6xE9que2UFq8xxRj:VC6CzEuzrjdj68xRQM:Rqt8kdAz2hr48WDyfNuU8UL584L6vXD4
```
<br>-----<br>

# MEC IaaS Deployments
Mobile Edge Computing (MEC) POD IaaS Build-Up <br>
<br>-----<br>
 This project aims to deploy: <br> 
(1) Openstack: Small Scale Openstack with Calico L3 Network Fabric , OpenBaton acting as Service Orchestrator <br>
Calico L3 Network Configuration Management:
```sh
Add following lines to /etc/bird/bird.conf @ bird (Route Reflector) machine <br>
protocol bgp ExtRouter {
  description "ExtRouter"; 
  local as 64511; 
  neighbor [Mikrotik-Router-IP-Addr] as 64511; 
  multihop; 
  rr client;
  import all;
  export all; 
} 
On the Mikrotik Router:<br>
(a) Change the AS number of the router: BGP → Instances, default, AS 64511, Client To Client Reflection ✓. <br>
(b) Add peers: BGP → Peers, Add New, Name "calico-bird", Remote address <bird-ip-addr>, Remote AS 64511, Route Reflect ✓. <br>
    -> Check status: BGP → Peers, note state=established <br>
```
(1-B) In order to pass sctp traffic following kernel modules needs to be loaded:<br>
sudo modprobe nf_conntrack_proto_sctp <br>
sudo modprobe nf_nat_proto_sctp <br>

(2) Kubernetes: Small Scale Kubernetes with available GPU installed nodes <br>
(2-A) We will setup Stern & Helm & Sysdig. <br>
(2-B) We will setup NFS & Samba for File Storage & Sharing Across K8S Nodes & Workloads. <br>
Details are in README inside the k8s-iaas folder.




