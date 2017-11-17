# mec
Mobile Edge Computing (MEC) POD IaaS Build-Up <br>

Deploying Ubuntu Openstack with KVM and Nova-LXD Hypervisors, together with Calico Network Fabric and OpenBaton as Service Orchestrator.

<br>-----<br>
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
(a) Change the AS number of the router: BGP → Instances, default, AS 64511, Client To Client Reflection ✓. <br>
(b) Add peers: BGP → Peers, Add New, Name "calico-bird", Remote address <bird-ip-addr>, Remote AS 64511, Route Reflect ✓. <br>
    -> Check status: BGP → Peers, note state=established <br>
<br>-----<br>
