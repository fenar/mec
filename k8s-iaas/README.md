# Installation 

## Kubernetes cluster 

First of all, deploy the minimal k8s cluster: 

```
juju deploy k8s-minimal.yaml
# ... wait until over
juju scp kubernetes-master/0:config ~/.kube/config

```

Eventually the tagging of nodes will fail. If that is the case, label the storage node manually: 

```
kubectl label nodes kontron-node01-cpu01 nodeType=storage
```

## Additional tooling

Install [stern](https://github.com/wercker/stern) and [helm](https://github.com/kubernetes/helm) on MAAS

To initialize Helm, first output the default install on the node and edit. An example is provided (tiller.yaml) that adds a nodeSelector to run on the only non GPU node, and force some resources. 

```
kubectl create -f tiller.yaml
```

## Download Charts

```
git clone https://github.com/madeden/charts.git
```


## Install Sysdig clients 

```
kubectl create -f sysdig.yaml
```

Note that the API token in there is temporary just for this project. You can change it if you take a subscription on sysdig.com

## Install NFS server

First of all make sure the storage node is labeled properly: 

```
 kubectl get nodes --show-labels
NAME                   STATUS    ROLES     AGE       VERSION   LABELS
kontron-node01-cpu01   Ready     <none>    20h       v1.8.2    beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=kontron-node01-cpu01,nodeType=storage
kontron-node07         Ready     <none>    20h       v1.8.2    beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,cuda=true,gpu=true,kubernetes.io/hostname=kontron-node07,nodeType=gpu
kontron-node08         Ready     <none>    20h       v1.8.2    beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,cuda=true,gpu=true,kubernetes.io/hostname=kontron-node08,nodeType=gpu
kontron-node09         Ready     <none>    20h       v1.8.2    beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,cuda=true,gpu=true,kubernetes.io/hostname=kontron-node09,nodeType=gpu
```

Then get onto the storage node and create the storage folders for NFS: 

```
juju ssh kubernetes-worker-storage/0

$ sudo mkdir -p /data/openalpr-data /data/openalpr-logs /pts-data
$ sudo chown -R ubuntu:ubuntu /data/openalpr-data /data/openalpr-logs /pts-data
$ sudo chmod -R a+rw /data/openalpr-data /data/openalpr-logs /pts-data
```

Exit from the server and transfer all data from the MAAS node onto the storage node. 

```
rsync -autvr -i /home/ubuntu/.local/share/juju/ssh/juju_id_rsa /srv/2ndMECHackathon/data/openalpr-data/ ubuntu@172.27.160.118:/data/openalpr-data/

rsync -autvr -i /home/ubuntu/.local/share/juju/ssh/juju_id_rsa /srv/2ndMECHackathon/data/openalpr-data/ ubuntu@172.27.160.118:/pts-data/

```

Now install NFS: 

```
helm install --name nfs --values nfs-alpr-values.yaml charts/nfs
helm install --name pts-nfs --values nfs-pts-values.yaml charts/nfs
```

Then edit the pvc-{alpr;pts}.yaml files with the IP addresses of the services which you can get via: 

``` 
$ kubectl get svc
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
kubernetes   ClusterIP   10.152.183.1     <none>        443/TCP                      21h
nfs-nfs      ClusterIP   10.152.183.233   <none>        20048/TCP,2049/TCP,111/TCP   17h
pts-nfs-nfs   ClusterIP   10.152.183.231   <none>        20048/TCP,2049/TCP,111/TCP   1m
```


Then create the pv and pvc mapped to NFS with: 

```
kubectl create -f pvc*.yaml
```

So at this point we are sharing the data for images and pts content with the upcoming containers. 

## Installing SAMBA

This service will help us when we deploy Keepixo. 

First of all we create a /data-samba folder on the storage node

```
juju ssh kubernetes-worker-storage/0

$ sudo mkdir -p /samba-data
$ sudo chown -R ubuntu:ubuntu /samba-data
$ sudo chmod -R a+rw /samba-data
```

exit and go back to the MAAS node to install the samba chart: 

```
helm install --name samba --values samba-values.yaml charts/samba
```

## Sending the runtime script

there is a small script to run openALPR in K8s to send on the storage: 

```
juju scp run-alpr.sh kubernetes-worker-storage/0:/data/
```

