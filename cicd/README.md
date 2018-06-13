Welcome to OPNFV CICD Host Machine Preparation
----

Scripts in this folder is to help you automate implementation of CICD Host as described by OPNFV.
Reference: https://wiki.opnfv.org/display/INF/How+to+Setup+CI+to+Run+OPNFV+Deployment+and+Testing

NOTES:
(*) It is assumed that you have prepared your lab with MaaS & Juju installed on Master Node and your servers are enlisted. <br>
(**) This setup to be used with Openstack Deployment implemented under fenar/openbaton-oam under git.<br>
https://github.com/fenar/openbaton-oam

Please execute as described below
----

(1) $ ./01-deploy-cicdhost.sh [enlisted-nodename-to-deploy] <br>
    This script will allocate a server from your MaaS and deploy Ubuntu OS and later install all tools required.

(2) Login to your Jenkins Web Portal http://ip:8080 with admin/<password*> <br>
    <password*> would be printed at the end of script execution. <br>
    Please save this password for later use! <br>
    Pick Default Plugins to be installed and continue with Admin user...
  
(3) $ ./02-installjenkins-plugins.sh <br>
     This script will install all required jenkins plugins for CI/CD Host.

(4) $./03-prepare-jumphost.sh [Jump-Host- ie where MaaS runs] <br>
     This script will add necessary components to your Jump-Host (MaaS).
     
(5) $./04-configure-jumphost-for-jenkins-user.sh [Jump-Host] <br>
     This script will create jenkins user with sshkeys setup on Jump-Host (MaaS).
     
(6) Manual Step: 
```sh
   Connect Jumphost to Jenkins<br>
            [Open Jenkins Web Interface]
            Click "Credentials" -> "Jenkins in second table" -> "Global Credentials" -> "Add Credentials"
            Fill in the boxes
            Kind: SSH username with private key
            Scope: System (Jenkins and nodes only)
            Username: jenkins
            Private Key: Enter directly and paste the private key of the jenkins user you created on the jumphost<br>
            Description: jenkins on vzw-pod1 jumphost
    Go back to Jenkins main page and click "Build Executor Status"
            [Click "New Node" and fill in the boxes]
            Node Name: vzw-pod1
            # of executors: 2
            Remote root directory: /home/jenkins/slave_root
            Labels: joid-baremetal
            Launch Method: Launch slave agents via ssh
            Host: IP of the jumphost
            Credentials: select the credentials you added as "jenkins on vzw-pod1 jumphost"
            Host Key Verification Strategy: Non verifying Verification Strategy
            Click Save
    The node should now be online with 2 executors<br>
```
(7) Manual Step: 
```sh
   Configure and Test Jenkins Job Builder
   [Login to CI host as jenkins]
   -> Update /etc/jenkins_jobs/jenkins_jobs.ini, 
      (Password is 'API Token' fields from: Jenkins Web Interface -> 'admin' -> 'Configure' -> 'Show API Token')
    
```     
(8) $./05-opnfv-jjb-setup-cicd.sh && $./06-opnfv-releng-setup-cicd.sh [CI/CD-Host] <br>
     These scripts will fetch RelEng Job from OPNFV Git Repo and checkout for local jenkins job build. <br>

(9) Please login to CI host and execute below commands. <br>
     cd ~/repos/releng/jjb/joid <br>
     vi joid-daily-jobs.yml <br>
```sh 
    !!!UPDATE THE LINE 142 WHERE THE GIT URL IS SPECIFIED!!!
    !!!url: 'ssh://<IP OF JUMPHOST>/home/jenkins/repos/{project}'!!!
 
    git add -A .
    git commit -m 'add vzw config'
    cd ~/repos/releng/jjb
    jenkins-jobs update joid/joid-daily-jobs.yml:functest/functest-daily-jobs.yml:yardstick/yardstick-daily-jobs.yml:global/installer-params.yml:global/slave-params.yml
 
```    
         
(10) $./07-deploy-testresultbackend.sh [CI/CD-Host] <br>
     These scripts will install InfluxdDB & Grafana [http://<CICD-HOST>:3000 admin/admin] to be used within CI/CD Setup. <br>
```sh
     Once install completed, following steps shall be followed:
     (a) Configure Jenkins to use InfluxDB @ Jenkins WebUI: Manage Jenkins -> Configure System -> new influxdb target
                # Url: http://localhost:8086/
                # Database: jenkins_data
                # User: admin
                # Password: admin
      (b) Configure Grafana to get data from InfluxDB
```
Date | Author(s):
(A) 07/9/2017 | Fatih E. NAR
