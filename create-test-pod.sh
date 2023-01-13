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
#oc apply -f ava-ocp-nfs-external-provisioner/test-claim.yaml
#oc apply -f ava-ocp-nfs-external-provisioner/test-pod.yaml
#oc -n $NameSpace get pvc,pod

