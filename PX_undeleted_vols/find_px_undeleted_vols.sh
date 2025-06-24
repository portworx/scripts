#!/bin/bash
namespace=portworx

# Fetch list of PVs from Kubernetes
k8s_pvs=$(kubectl get pv -o jsonpath='{.items[*].metadata.name}')

# Convert to array
read -ra k8s_pv_array <<< "$k8s_pvs"

# Fetch list of volume names from pxctl
px_vols=$(kubectl -n ${namespace} exec service/portworx-service -c portworx -- /opt/pwx/bin/pxctl volume list -j | jq -r '.[] | "\(.locator.name)"')

# Initialize missing list
echo "Volumes in pxctl but NOT in Kubernetes:"

echo "VolName - VolID - VolState - VolStatus - Parentvol(ifsnap) - CreatedTime - LastAttachedTime - LastDetachedTime - FSFormat - AttachedNode - AttachedState"

for vol in $px_vols; do
  if [[ ! " ${k8s_pv_array[@]} " =~ " ${vol} " ]]; then
          kubectl -n ${namespace} exec service/portworx-service -c portworx -- /opt/pwx/bin/pxctl volume inspect $vol --json | jq -r '.[] | "\(.locator.name) - \(.id) - \(.state) - \(.status) - \(.source.parent) - \(.ctime) - \(.attach_time) - \(.detach_time) - \(.format) - \(.attached_on) - \(.attached_state)"'
  fi
done
