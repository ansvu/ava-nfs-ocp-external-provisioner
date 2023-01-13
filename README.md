# Ava OCP NFS External Provisioner Helm Chart
Based on Manual steps from follow link [NFS subdir external provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner) And this [nfs-subdir-helm-chart](https://artifacthub.io/packages/helm/nfs-subdir-external-provisioner/nfs-subdir-external-provisioner)

Credits to them all! I did not modify much but just simplify by using Manual Steps from github into helm chart(less files). For Advance NFS, please follow original github and nfs helm-charts.

## Prerequisites

- Kubernetes >=1.9
- Existing NFS Server and Share
- HelmV3
- Clone this github
- Make sure cluster is reachable to NFS server either ipv4 or ipv6

## Installing the NFS Helm Chart
### NFS Chart Structure
```console
tree ava-ocp-nfs-external-provisioner/
ava-ocp-nfs-external-provisioner/
├── Chart.yaml
├── templates
│   ├── deployment.yaml
│   ├── _helpers.tpl
│   ├── rbac.yaml
│   └── storageclass.yaml
├── test-claim.yaml
├── test-pod.yaml
└── values.yaml
```
### With Custom Values.yaml
Assume to update values.yaml according to your needs and lab environment

**values.yaml:**
```yaml
replicaCount: 1
strategyType: Recreate

image:
  repository: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner
  tag: v4.0.2
  pullPolicy: IfNotPresent
imagePullSecrets: []

nfs:
  server: 2600:52:7:76::108
  path: /data/nfshare
  mountOptions:
  volumeName: nfs-client-root
  reclaimPolicy: Retain

storageClass:
  name: ava-nfs-client-sc        
  create: true
  provisionerName: k8s-sigs.io/nfs-subdir-external-provisioner
  defaultClass: true
  allowVolumeExpansion: true
  reclaimPolicy: Delete
  archiveOnDelete: true
  onDelete:
  pathPattern:

  # Set access mode - ReadWriteOnce, ReadOnlyMany or ReadWriteMany
  accessModes: ReadWriteOnce

  # Set volume bindinng mode - Immediate or WaitForFirstConsumer
  volumeBindingMode: Immediate

  # Storage class annotations
  annotations: {}

#leaderElection:
  # When set to false leader election will be disabled
  #  enabled: true

podAnnotations: {}

## Set pod priorityClassName
# priorityClassName: ""

securityContext:
 fsGroup: 1000
 runAsUser: 1000

serviceAccount:
  create: true
  annotations: {}
  name: nfs-client-provisioner

resources: {}
  # limits:
  #  cpu: 100m
  #  memory: 128Mi
  # requests:
  #  cpu: 100m
  #  memory: 128Mi

nodeSelector: {}
tolerations: []
affinity: {}

# Additional labels for any resource created
labels: nfs-client-provisioner
```
- Create namespace 
```console
$ oc create ava-nfs
```
```console
$ helm install ava-nfs-subdir-external-provisioner -n ava-nfs ava-ocp-nfs-external-provisioner \
    --timeout=30s
```
### With Custom Values.yaml
```console
$ helm install ava-nfs-subdir-external-provisioner -n ava-nfs ava-ocp-nfs-external-provisioner \
    --set nfs.server=2600:52:7:76::108 \
    --set nfs.path=/data/nfshare \
    --set storageClass.name=ava-nfs-sc \
    --set storageClass.provisionerName=k8s-sigs.io/ava-ocp-nfs-external-provisioner \
    --timeout=30s
```
## Create Test Claim and POD
create-test-pod.sh:
```bash
#!/bin/bash

# Prints all parameters to stdout, prepends with a timestamp.
log() {
        printf '%s %s\n' "$(date +"%Y%m%d-%H:%M:%S")" "$*"
}

# Prints all parameters and exits with the error code.
bye() {
        log "$*"
        exit 1
}
# Checks whether files or directories exist.
file_exists() {
        [ -z "${1-}" ] && bye Usage: file_exists name.
        ls "$1" >/dev/null 2>&1
}
#############################################################
NameSpace=$1

#check if ava-ocp-nfs-external-provisioner/ chart dir existed#
if [[ ! -d ava-ocp-nfs-external-provisioner ]]; then
     log "INFO: ava-ocp-nfs-external-provisioner chart directory is not existed!"
     exit 1
fi

if [[ $NameSpace == "" ]]; then
     NameSpace="test-claim-pvc"
fi

StorageClassName=$(cat ava-ocp-nfs-external-provisioner/values.yaml|awk '/storageClass/{getline; print}'| awk '{print $2}')
oc get ns | grep -w "$NameSpace" >/dev/null 2>&1
if [ $? -eq 1 ]; then
    log INFO: $NameSpace is not created yet, start creating it now...
    oc create ns "$NameSpace"
fi

sed -i'' "s/storageClassName:.*/storageClassName: $StorageClassName/g" ava-ocp-nfs-external-provisioner/test-claim.yaml

# Create test-claim and test-pod
oc apply -f ava-ocp-nfs-external-provisioner/test-claim.yaml
oc apply -f ava-ocp-nfs-external-provisioner/test-pod.yaml
oc -n $NameSpace get pvc,pod
```
- Start Create Test Claim and POD
```shellSession
$ bash create-test-pod.sh test-namespace
or
$ bash create-test-pod.sh
```
Note: if namespace is not provided then it create default namespace: test-claim-pvc automatic

## Uninstalling the Chart

To uninstall/delete the `ava-nfs-subdir-external-provisioner` deployment:

```console
$ helm uninstall ava-nfs-subdir-external-provisioner -n ava-nfs 
```
The command removes all the Kubernetes components associated with the chart and deletes the release.
