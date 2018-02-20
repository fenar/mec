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
    Add following lines to /etc/bird/bird.conf @ bird (Route Reflector) machine <br>
```sh
protocol bgp ExtRouter {
  description "ExtRouter"; 
  local as 64511; 
  neighbor [Mikrotik-Router-IP-Addr] as 64511; 
  multihop; 
  rr client;
  import all;
  export all; 
} 
```
On the Mikrotik Router:<br>
```sh
(a) Change the AS number of the router: BGP → Instances, default, AS 64511, Client To Client Reflection ✓. <br>
(b) Add peers: BGP → Peers, Add New, Name "calico-bird", Remote address <bird-ip-addr>, Remote AS 64511, Route Reflect ✓. <br>
    -> Check status: BGP → Peers, note state=established <br>
<br>-----<br>
(2) Kubernetes: Small Scale Kubernetes with available GPU installed nodes <br>
```

















