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
juju resolved --no-retry kubernetes-worker-storage/0
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

$ sudo mkdir -p /data/openalpr-data /data/openalpr-logs /pts-data /tf-data
$ sudo chown -R ubuntu:ubuntu /data/openalpr-data /data/openalpr-logs /pts-data /tf-data
$ sudo chmod -R a+rw /data/openalpr-data /data/openalpr-logs /pts-data /tf-data
```

Create the same folders on all worker nodes

```
juju ssh kubernetes-worker/<worker id> 

$ sudo mkdir -p /data/openalpr-data /data/openalpr-logs /pts-data /tf-data
$ sudo chown -R ubuntu:ubuntu /data/openalpr-data /data/openalpr-logs /pts-data /tf-data
$ sudo chmod -R a+rw /data/openalpr-data /data/openalpr-logs /pts-data /tf-data
```

Exit from the server and transfer all data from the MAAS node onto all nodes. 

First download data and scripts for tensorflow: 

```
curl -sL -o cifar.tgz https://www.cs.toronto.edu/~kriz/cifar-10-python.tar.gz
tar xfz cifar.tgz
mv cifar-10-batches-py/ /tf-data/cifar-10
rm -f cifar.tgz

cd /tf-data
git clone https://github.com/tensorflow/benchmarks.git
git clone https://github.com/tensorflow/models.git
```

then 

```
rsync -autvr -i ./openalpr-data/ ubuntu@<kubernetes-worker-storage/0 IP Address>:/data/openalpr-data/

rsync -autvr -i ./pts-data/ ubuntu@<kubernetes-worker-storage/0 IP Address>:/pts-data/

rsync -autvr -i ./tf-data/ ubuntu@<kubernetes-worker-storage/0 IP Address>:/tf-data/
```

Repeat the rsync operation on all worker nodes as well. 

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

## Sending the runtime scripts

there is a small script to run openALPR in K8s to send on the storage: 

```
juju scp run-alpr.sh kubernetes-worker-storage/0:/data/
juju scp run-pts.sh kubernetes-worker-storage/0:/pts-data/
```

# Running Benchmarks
## OpenALPR

This benchmark is running plate recognition on a set of fixed JPEG and BMP images. Each image is processed and the results are outputted to a json file named after the process that ran the analysis. 

The image source for each container is /data, in which there the 2 subfolders we created before are present: openalpr-data and alpr-logs. 

the test script is loaded dynamically from /data to avoid updating the containers after deployment. 

We prepare a set of Helm values.yaml file which implement different resource allocation strategies: 

```
# Type is a simple test differenciator
type: ktrn

# How many times do we run each benchmark AT THE SAME TIME. 
# Note that if this number exceeds the total number of GPUs and 
# the test is set to gpu mode, then some pods will not be scheduled
parallelism: 1

# Provide indications on resource quotas. Helps understand the profile of the app 
resources:
  requests:
    cpu: 100m
    memory: 8Gi
  limit:
    cpu: 100m
    memory: 32Gi

# Is this a GPU Benchmark? If true, inidicate the type of GPU nvidia or amd. Otherwise set to anything
gpuType: cpu

# Change this if you have several scripts
command: [ "/data/run-alpr.sh" ]

# Where to load storage from
storage:
  name: nfs-nfs

# If run in GPU mode, you must also change the library in the config file. 
# You can also change settings to understand the profile. 
openalprConfig: |-
  runtime_dir = ${CMAKE_INSTALL_PREFIX}/share/openalpr/runtime_data
  ocr_img_size_percent = 1.33333333
  state_id_img_size_percent = 2.0
  prewarp =
  max_plate_width_percent = 100
  max_plate_height_percent = 100
  detection_iteration_increase = 1.1
  detection_strictness = 3
  max_detection_input_width = 1280
  max_detection_input_height = 720
  ; lbpcpu    - default LBP-based detector uses the system CPU  
  ; lbpgpu    - LBP-based detector that uses Nvidia GPU to increase recognition speed.
  ; lbpopencl - LBP-based detector that uses OpenCL GPU to increase recognition speed.  Requires OpenCV 3.0
  ; morphcpu  - Experimental detector that detects white rectangles in an image.  Does not require training.
  detector = lbpcpu
  must_match_pattern = 0
  skip_detection = 0
  detection_mask_image = 
  analysis_count = 1
  contrast_detection_threshold = 0.3
  max_plate_angle_degrees = 15
  ocr_min_font_point = 6
  postprocess_min_confidence = 65
  postprocess_confidence_skip_level = 80
  debug_general         = 0
  debug_timing          = 0
  debug_detector        = 0
  debug_prewarp         = 0
  debug_state_id        = 0
  debug_plate_lines     = 0
  debug_plate_corners   = 0
  debug_char_segment    = 0
  debug_char_analysis   = 0
  debug_color_filter    = 0
  debug_ocr             = 0
  debug_postprocess     = 0
  debug_show_images     = 0
  debug_pause_on_frame  = 0
```

Prepare variations with allocations of various CPU quotas (2, 4, 8, 16 and 32) for cpu and nvidia mode, and  run the tests with: 

```
helm install charts/openalpr --name cpu-2c alpr-cpu-2c-values.yaml
```

once all benchmarks have run, we can download the json files and start analyzing results. 

## Phoronix Test Suite

PTS is a well recognized benchmarking solution for Linux. It contains numerous benchmarks targetting CPU, RAM, IO or system in general and represent a wide array of use cases from Cryptography to hosting blogs and files, gaming, transcoding, file processing or just pure system stressing. 

In order to understand how each individual benchmark is impacted by noisy neighbors, the test protocol is slightly different than before.

First of all se run each of the selected benchmarks once and with full access the machine, to qualify raw performance. 
Then we run, on the same machine, all tests at the same time to sustainably load the system and discover impacts of benchmarks on one another. 

The first iteration consist in manually schedulint the benchmarks and tracking the results: 

```
# Node07
helm install charts/pts --name pts-dbench-alone --values day3/pts-dbench-values.yaml
sleep 14400 
helm install charts/pts --name pts-blender-alone --values day3/pts-blender-values.yaml
sleep 22000
# Node 08
helm install charts/pts --name pts-aio-stress-alone --values day3/pts-aio-stress-values.yaml
sleep 100
helm install charts/pts --name pts-x264-alone --values day3/pts-x264-values.yaml
sleep 120
helm install charts/pts --name pts-ffmpeg-alone --values day3/pts-ffmpeg-values.yaml
sleep 200
helm install charts/pts --name pts-rbenchmark-alone --values day3/pts-rbenchmark-values.yaml
sleep 200
helm install charts/pts --name pts-system-libjpeg-alone --values day3/pts-system-libjpeg-values.yaml
sleep 200 
helm install charts/pts --name pts-blake2-alone --values day3/pts-blake2-values.yaml
sleep 360
helm install charts/pts --name pts-bork-alone --values day3/pts-bork-values.yaml
sleep 360
helm install charts/pts --name pts-x264-opencl-alone --values day3/pts-x264-opencl-values.yaml
sleep 500
helm install charts/pts --name pts-go-benchmark-alone --values day3/pts-go-benchmark-values.yaml
sleep 700 
helm install charts/pts --name pts-blogbench-alone --values day3/pts-blogbench-values.yaml
sleep 750
helm install charts/pts --name pts-cachebench-alone --values day3/pts-cachebench-values.yaml
sleep 750
helm install charts/pts --name pts-postmark-alone --values day3/pts-postmark-values.yaml
sleep 1000
helm install charts/pts --name pts-numpy-alone --values day3/pts-numpy-values.yaml
sleep 3600 
helm install charts/pts --name pts-fs-mark-alone --values day3/pts-fs-mark-values.yaml
sleep 3600
helm install charts/pts --name pts-iozone-alone --values day3/pts-iozone-values.yaml
sleep 7300
```

Once we are done with that we can run the load test overnight (it is planed for 6hrs without competition for resources)

```
helm install charts/pts --name pts-load --values pts-concurrent-values.yaml
```

All results are collected in /pts-data/test-results and can be collected afterwards. 

The configuration file is similar to OpenALPR as well: 

```
# Names of benchmarks to run in // as list
# completions indicate how many consecutive times it will run
# parallelism allows for control of simultaneous instances
# image allows to pick different docker images for different tests
# gpuType allows to query for a GPU pod instead of a pure CPU
benchmarks: 
- name: pts/x264
  completions: 1
  parallelism: 1
  image: samnco/pts:7.4.0-nocuda
  gpuType: cpu

# Resource management can be active or disabled. 
resources:
  manage: false
  requests:
    cpu: 4000m
    memory: 8Gi
  limits:
    cpu: 4000m
    memory: 12Gi

# Specify a node for running the workload
nodeSelector:
  kubernetes.io/hostname: kontron-node08

# This allows to load data from network or from hostPath
persistence:
  # This setup overrides persistence and mounts a hostPath. Use the host path 
  # as the value
  hostPath: /pts-data

  ## This volume persists generated configuration files, keys, and certs.
  ##
  enabled: true

  ## A manually managed Persistent Volume and Claim
  ## Requires persistence.enabled: true
  ## If defined, PVC must be created manually before volume will be bound
  existingClaim: 

# All benchmarks will inherit this config
config: 
  <?xml version="1.0"?>
  <!--Phoronix Test Suite v7.4.0-->
  <?xml-stylesheet type="text/xsl" href="xsl/pts-user-config-viewer.xsl"?>
  <PhoronixTestSuite>
    <Options>
      <OpenBenchmarking>
        <AnonymousUsageReporting>TRUE</AnonymousUsageReporting>
        <IndexCacheTTL>3</IndexCacheTTL>
        <AlwaysUploadSystemLogs>FALSE</AlwaysUploadSystemLogs>
      </OpenBenchmarking>
      <General>
        <DefaultBrowser></DefaultBrowser>
        <UsePhodeviCache>TRUE</UsePhodeviCache>
        <DefaultDisplayMode>DEFAULT</DefaultDisplayMode>
        <PhoromaticServers></PhoromaticServers>
        <FullOutput>FALSE</FullOutput>
      </General>
      <Modules>
        <LoadModules>toggle_screensaver, update_checker, perf_tips, ob_auto_compare</LoadModules>
      </Modules>
      <Installation>
        <RemoveDownloadFiles>FALSE</RemoveDownloadFiles>
        <SearchMediaForCache>TRUE</SearchMediaForCache>
        <SymLinkFilesFromCache>FALSE</SymLinkFilesFromCache>
        <PromptForDownloadMirror>FALSE</PromptForDownloadMirror>
        <EnvironmentDirectory>~/.phoronix-test-suite/installed-tests/</EnvironmentDirectory>
        <CacheDirectory>~/.phoronix-test-suite/download-cache/</CacheDirectory>
      </Installation>
      <Testing>
        <SaveSystemLogs>TRUE</SaveSystemLogs>
        <SaveInstallationLogs>FALSE</SaveInstallationLogs>
        <SaveTestLogs>TRUE</SaveTestLogs>
        <RemoveTestInstallOnCompletion></RemoveTestInstallOnCompletion>
        <ResultsDirectory>~/.phoronix-test-suite/test-results/</ResultsDirectory>
        <AlwaysUploadResultsToOpenBenchmarking>FALSE</AlwaysUploadResultsToOpenBenchmarking>
        <AutoSortRunQueue>TRUE</AutoSortRunQueue>
      </Testing>
      <TestResultValidation>
        <DynamicRunCount>TRUE</DynamicRunCount>
        <LimitDynamicToTestLength>20</LimitDynamicToTestLength>
        <StandardDeviationThreshold>3.50</StandardDeviationThreshold>
        <ExportResultsTo></ExportResultsTo>
        <MinimalTestTime>3</MinimalTestTime>
      </TestResultValidation>
      <BatchMode>
        <SaveResults>TRUE</SaveResults>
        <OpenBrowser>FALSE</OpenBrowser>
        <UploadResults>FALSE</UploadResults>
        <PromptForTestIdentifier>FALSE</PromptForTestIdentifier>
        <PromptForTestDescription>FALSE</PromptForTestDescription>
        <PromptSaveName>FALSE</PromptSaveName>
        <RunAllTestCombinations>TRUE</RunAllTestCombinations>
        <Configured>TRUE</Configured>
      </BatchMode>
      <Networking>
        <NoInternetCommunication>FALSE</NoInternetCommunication>
        <NoNetworkCommunication>FALSE</NoNetworkCommunication>
        <Timeout>20</Timeout>
        <ProxyAddress></ProxyAddress>
        <ProxyPort></ProxyPort>
        <ProxyUser></ProxyUser>
        <ProxyPassword></ProxyPassword>
      </Networking>
      <Server>
        <RemoteAccessPort>8080</RemoteAccessPort>
        <Password></Password>
        <WebSocketPort>8081</WebSocketPort>
        <AdvertiseServiceZeroConf>FALSE</AdvertiseServiceZeroConf>
        <PhoromaticStorage>~/.phoronix-test-suite/phoromatic/</PhoromaticStorage>
      </Server>
    </Options>
  </PhoronixTestSuite>
    
```

## Tensorflow

We run 2 versions of the benchmark:
* With real data based on CIFAR10
* With synthetic data auto generated. This example is closer to norma benchmarks. 

```
helm install charts/tf-benchmarks --name tf-cifar10 --values tf-benchmark-cifar10-values.yaml
helm install charts/tf-benchmarks --name tf-synthetic --values tf-benchmark-synthetic-values.yaml
```


