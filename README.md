# MEC SWITCH FABRIC
Mobile Edge Computing (MEC) POD IaaS Build-Up <br>
<br>-----<br>
# MAAS & JUJU SETUP
```sh
ubuntu@OrangeBox140:~/.local/share/juju$ cat clouds.yaml <br>
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
ubuntu@OrangeBox140:~/.local/share/juju$ cat accounts.yaml 
controllers:
  maas-v4n140-controller:
    user: admin
    password: 8df9ceaae168a15c00265e9d4b9803c8
    last-known-access: superuser
ubuntu@OrangeBox140:~/.local/share/juju$ 
```
<br>-----<br>


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

# How to Prepare and Create Images for OpenStack LXD-Zones

Rest of the section will discuss the preparation and creation of images for OpenStack LXD-Zones. Preparation will require the use of cloud-init which is a package installed in lxc/lxd distribution and the use of config.yml file for providing one’s public ssh key.<br><br>

Create config.yml with the following contents:<br>
#cloud-config 
ssh_authorized_keys: 
 - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCsdqsJVtBBwydHM2Gjy9B3JI5q8Qgk85wiQ6D/mwUVRlroC0BBQzru+alAheO+twt3Z3nvujxB9XJRa7+lKviFCxya/j4JtmfLNm3qVA+Y0BIlbQCA7gbnhl47nXPe5uOFyp/RbhLZLu7oaBHrUfto/GLh0sLOgv1JVZJLyxa8L4KLZVvSKYW9HEj/DBk8oEg1G66HGGxcczOu/XAF+DL0XPCfuit+cYbMNugb5OZDlOgeTjnk1OJGxG4VfMdji+8JwumKvPk/gM0YvvE5hDLn/xC6BUlRt2AJRtn0yVGh/q6jMAGeTOmSsK/J+6TYWV/5tF/8ML614kaklYI9X1Gz victor@victor-VirtualBox 
<br>
Initialize a container with id_rsa.pub key:<br>
$ lxc init <image name or fingerprint> hssdb 
$ lxc config set hssdb user.user-data - < config.yml 
$ lxc start hssdb 
<br>
Verify ssh capabilities (should not get Permission Denied Error)  <br>
$ lxc info hssdb 
            eth0: IPV4     10.162.231.177 
$ ssh ubuntu@10.162.231.177 
ubuntu@hssdb $ exit 
<br>
Make changes to hssdb to create a working HSS MySQL backend <br>
$ lxc exec hssdb bash <br>
// — make the changes within container <br>
// — refer to InstallationOfAnHssMicroServiceWithContainers.docx <br>
root@hssdb $ exit <br>
<br>
Image creation <br>
$ lxc stop hssdb <br>
$ lxc publish hssdb —alias hssdb-image <br>
$ lxc image export hssdb-image hssdb <br>
// Result => Output is in hssdb.tar.gz <br>
<br>
// hssdb.tar.gz contains all directories under /rootfs <br>
// lxd-zone images will not work with /rootfs <br>
// /rootfs upper directory will be removed <br>
<br>
$ mkdir temp <br>
$ mv hssdb.tar.gz temp/ <br>
$ cd temp/ <br>
$ sudo tar xvzf hssdb.tar.gz <br>
$ cd rootfs/ <br>
<br>
// Create the tar file that is acceptable for LXD-Zones <br>
$ sudo tar cvzf hssdbNonRoot.tar.gz bin/  boot/  dev/  etc/  home/  lib/  lib64/  media/  mnt/  opt/  proc/  root/  run/  sbin/  snap/  srv/  sys/  tmp/  usr/  var/   <br>
<br>
$ cd ../.. <br>
$ mkdir nonrootfstar  // Directory for acceptable LXD-Zone tarballs <br>
$ sudo mv temp/rootfs/hssdbNonRoot.tar.gz nonrootfstar/. <br>
<br>
This process can be followed for other images such as dmd, hsscx1, hsscx3, cxclient, etc.<br>














