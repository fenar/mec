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
(2) Kubernetes: Small Scale Kubernetes with available GPU installed nodes <br>
(2-A) $ juju scp kubernetes-master/0:config ~/.kube/config <br>
(2-B) We will setup Stern & Helm & Sysdig. 
```sh
(i) Stern allows you to tail multiple pods on Kubernetes and multiple containers within the pod. Each result is color coded for quicker debugging. Install from https://github.com/wercker/stern
(ii) Helm is a tool for managing Kubernetes charts. Charts are packages of pre-configured Kubernetes resources
Helm has two parts: 
(X) a client (helm) which runs on your MaaS Node. Install from https://github.com/kubernetes/helm
(XX) a server (tiller) that runs inside of your Kubernetes cluster, and manages releases (installations) of your charts.
$ kubectl create -f /srv/mec/k8s-iaas/tiller.yaml
(iii) Sysdig is Agent based Node Monitoring Tool.
$ kubectl create -f /srv/mec/k8s-iaas/sysdig.yaml
```
(2-C) We will setup NFS & Samba for File Storage & Sharing Across K8S Nodes & Workloads.
```sh
(i) 
juju ssh kubernetes-worker-storage/0
$ sudo mkdir -p /data/openalpr-data /data/openalpr-logs /pts-data /tf-data
$ sudo chown -R ubuntu:ubuntu /data/openalpr-data /data/openalpr-logs /pts-data /tf-data /data
$ sudo chmod -R a+rw /data/openalpr-data /data/openalpr-logs /pts-data /tf-data /data
(ii)
juju ssh kubernetes-worker/<worker id>
$ sudo mkdir -p /data/openalpr-data /data/openalpr-logs /pts-data /tf-data
$ sudo chown -R ubuntu:ubuntu /data/openalpr-data /data/openalpr-logs /pts-data /tf-data
$ sudo chmod -R a+rw /data/openalpr-data /data/openalpr-logs /pts-data /tf-data
(iii)
$ rsync -autvr -i /home/ubuntu/.local/share/juju/ssh/juju_id_rsa /srv/2ndMECHackathon/data/openalpr-data/ ubuntu@172.27.160.118:/data/openalpr-data/
$ rsync -autvr -i /home/ubuntu/.local/share/juju/ssh/juju_id_rsa /srv/2ndMECHackathon/data/openalpr-data/ ubuntu@172.27.160.118:/pts-data/
(iv)
Now install NFS:
$ helm install --name nfs --values nfs-alpr-values.yaml charts/nfs
$ helm install --name pts-nfs --values nfs-pts-values.yaml charts/nfs
(v)
Then edit the pvc-{alpr;pts}.yaml files with the IP addresses of the services which you can get via:

$ kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
kubernetes   ClusterIP   10.152.183.1     <none>        443/TCP                      21h
nfs-nfs      ClusterIP   10.152.183.233   <none>        20048/TCP,2049/TCP,111/TCP   17h
pts-nfs-nfs   ClusterIP   10.152.183.231   <none>        20048/TCP,2049/TCP,111/TCP   1m

Then create the pv and pvc mapped to NFS with:
$ kubectl create -f pvc*.yaml
(!) So at this point we are sharing the data for images and pts content with the upcoming containers.


(vi) Installing SAMBA
This service will help us on workload executions.
First of all we create a /data-samba folder on the storage node
$ juju ssh kubernetes-worker-storage/0

$ sudo mkdir -p /samba-data
$ sudo chown -R ubuntu:ubuntu /samba-data
$ sudo chmod -R a+rw /samba-data
exit and go back to the MAAS node to install the samba chart:

$helm install --name samba --values samba-values.yaml charts/samba

```



