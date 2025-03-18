#!/bin/bash
# ================================================================
# Script: PX_Gather_Logs.sh
# Description: Collects logs and other ifnormation related to portworx/PX Backup.
# Usage:
# - We can pass the inputs as parameters like below
#   For Portworx : PX_Gather_Logs.sh -n <Portworx namespace> -c <k8s cli> -o PX
#       Example: PX_Gather_Logs.sh -n portworx -c kubectl -o PX
#   For PX Backup: PX_Gather_Logs.sh -n <Portworx Backup namespace> -c <k8s cli> -o PXB
#       Example: PX_Gather_Logs.sh -n px-backup -c oc -o PXB
# - If there are no parameters passed, shell will prompt for input
#
# ================================================================

# Function to display usage
usage() {
  echo "Usage: $0 [-n <namespace>] [-c <cli>] [-o <option>]"
  echo "  -n <namespace> : Kubernetes namespace"
  echo "  -c <cli>       : CLI tool to use (oc/kubectl)"
  echo "  -o <option>    : Operation option (PX/PXB)"
  exit 1
}
# Function to print progress

print_progress() {
    local current_stage=$1
    local total_stages="7"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Extracting $current_stage/$total_stages..."
}

# Parse command-line arguments
while getopts "n:c:o:" opt; do
  case $opt in
    n) namespace="$OPTARG" ;;
    c) cli="$OPTARG" ;;
    o) option="$OPTARG" ;;
    *) usage ;;
  esac
done

# Prompt for namespace if not provided
if [[ -z "$namespace" ]]; then
  read -p "Enter the namespace: " namespace
  if [[ -z "$namespace" ]]; then
    echo "Error: Namespace cannot be empty."
    exit 1
  fi
fi

# Prompt for k8s CLI  if not provided
if [[ -z "$cli" ]]; then
  read -p "Enter the k8s CLI  (oc/kubectl): " cli
  if [[ "$cli" != "oc" && "$cli" != "kubectl" ]]; then
    echo "Error: Invalid k8s CLI . Choose either 'oc' or 'kubectl'."
    exit 1
  fi
fi

# Prompt for option if not provided
if [[ -z "$option" ]]; then
  read -p "Choose an option (PX/PXB) (Enter PX for Portworx Enterprise/CSI, Enter PXB for PX Backup): " option
  if [[ "$option" != "PX" && "$option" != "PXB" ]]; then
    echo "Error: Invalid option. Choose either 'PX' or 'PXB'."
    exit 1
  fi
fi


# Confirm inputs
echo "$(date '+%Y-%m-%d %H:%M:%S'): Namespace: $namespace"
echo "$(date '+%Y-%m-%d %H:%M:%S'): CLI tool: $cli"
echo "$(date '+%Y-%m-%d %H:%M:%S'): option: $option"
# Set commands based on the chosen option
if [[ "$option" == "PX" ]]; then
  admin_ns=$($cli -n $namespace get stc -o yaml|grep admin-namespace|cut -d ":" -f2|tr -d " ")
  admin_ns="${admin_ns:-kube-system}"
  sec_enabled=$($cli -n $namespace get stc -o=jsonpath='{.items[*].spec.security.enabled}')


  commands=(
    "get pods -o wide -n $namespace"
    "get pods -o wide -n $namespace -o yaml"
    "describe pods -n $namespace"
    "get nodes -o wide -n $namespace"
    "get nodes -o wide -n $namespace -o yaml"
    "describe nodes -n $namespace"
    "get events -A --sort-by=.lastTimestamp"
    "get stc -o yaml -n $namespace"
    "describe stc -n $namespace"
    "get deploy -o wide -n $namespace"
    "get deploy -o wide -n $namespace -o yaml"
    "describe deploy -n $namespace"
    "get volumeattachments"
    "get volumeattachments -o yaml"
    "get csidrivers"
    "get csinodes"
    "get csinodes -o yaml"
    "get all -o wide -n $namespace"
    "describe all -n $namespace"
    "get all -o wide -n $namespace -o yaml"
    "get configmaps -n $namespace"
    "describe namespace $namespace"
    "get namespace $namespace -o yaml"
    "get pvc -n $namespace"
    "get pvc -n $namespace -o yaml"
    "get secret -n $namespace"
    "get sc"
    "get sc -o yaml"
    "get pvc -A"
    "get pv"
    "get sn -n $namespace"
    "get mutatingwebhookconfiguration"
    "get mutatingwebhookconfiguration -o yaml"
    "get svc,ep -o wide -n $namespace"
    "get svc,ep -o yaml -n $namespace"
    "get ds -o yaml -n $namespace"
    "get pdb -n $namespace"
    "get pdb -n $namespace -o yaml"
    "get pods -n kube-system -o wide"
    "version"
    "get autopilotrules"
    "get autopilotrules -o yaml"
    "get autopilotruleobjects -A"
    "get autopilotruleobjects -A -o yaml"
    "get applicationbackups -A"
    "get applicationbackups -A -o yaml"
    "get applicationbackupschedule -A"
    "get applicationbackupschedule -A -o yaml"
    "get applicationrestores -A"
    "get applicationrestores -A -o yaml"
    "get applicationregistrations -A"
    "get applicationregistrations -A -o yaml"
    "get backuplocations -A"
    "get backuplocations -A -o yaml"
    "get volumesnapshots -A"
    "get volumesnapshots -A -o yaml"
    "get volumesnapshotcontents"
    "get volumesnapshotcontents -o yaml"
    "get volumesnapshotdatas -A"
    "get volumesnapshotdatas -A -o yaml"
    "get volumesnapshotschedules -A"
    "get volumesnapshotschedules -A -o yaml"
    "get volumesnapshotrestores -A"
    "get volumesnapshotrestores -A -o yaml"
    "get schedulepolicies"
    "get schedulepolicies -o yaml"
    
  )
  output_files=(
    "k8s_px/px_pods.txt"
    "k8s_px/px_pods.yaml"
    "k8s_px/px_pods_desc.txt"
    "k8s_oth/k8s_nodes.txt"
    "k8s_oth/k8s_nodes.yaml"
    "k8s_oth/k8s_nodes_desc.txt"
    "k8s_oth/k8s_events_all.txt"
    "k8s_px/px_stc.yaml"
    "k8s_px/px_stc_desc.txt"
    "k8s_px/px_deploy.txt"
    "k8s_px/px_deploy.yaml"
    "k8s_px/px_deploy_desc.txt"
    "k8s_oth/volumeattachments.txt"
    "k8s_oth/volumeattachments.yaml"
    "k8s_oth/csidrivers.txt"
    "k8s_oth/csinodes.txt"
    "k8s_oth/csinodes.yaml"
    "k8s_px/px_all.txt"
    "k8s_px/px_all_desc.txt"
    "k8s_px/px_all.yaml"
    "k8s_px/px_cm.txt"
    "k8s_px/px_ns_dec.txt"
    "k8s_px/px_ns_dec.yaml"
    "k8s_px/px_pvc.txt"
    "k8s_px/px_pvc.yaml"
    "k8s_px/px_secret_list.txt"
    "k8s_oth/sc.txt"
    "k8s_oth/sc.yaml"
    "k8s_oth/pvc_list.txt"
    "k8s_oth/pv_list.txt"
    "k8s_oth/storagenodes_list.txt"
    "k8s_oth/mutatingwebhookconfiguration.txt"
    "k8s_oth/mutatingwebhookconfiguration.yaml"
    "k8s_px/px_svc_ep.txt"
    "k8s_px/px_svc_ep.yaml"
    "k8s_px/px_ds.yaml"
    "k8s_px/px_pdb.txt"
    "k8s_px/px_pdb.yaml"
    "k8s_oth/pods_kube_system.txt"
    "k8s_oth/k8s_version.txt"
    "k8s_px/autopilotrules.txt"
    "k8s_px/autopilotrules.yaml"
    "k8s_px/autopilotruleobjects.txt"
    "k8s_px/autopilotruleobjects.yaml"
    "k8s_bkp/pxb_applicationbackups.txt"
    "k8s_bkp/pxb_applicationbackups.yaml"
    "k8s_bkp/pxb_applicationbackupschedules.txt"
    "k8s_bkp/pxb_applicationbackupschedules.yaml"
    "k8s_bkp/pxb_applicationrestores.txt"
    "k8s_bkp/pxb_applicationrestores.yaml"
    "k8s_bkp/pxb_applicationregistrations.txt"
    "k8s_bkp/pxb_applicationregistrations.yaml"
    "k8s_bkp/pxb_backuplocations.txt"
    "k8s_bkp/pxb_backuplocations.yaml"
    "k8s_bkp/pxb_volumesnapshots.txt"
    "k8s_bkp/pxb_volumesnapshots.yaml"
    "k8s_bkp/pxb_volumesnapshotcontents.txt"
    "k8s_bkp/pxb_volumesnapshotcontents.yaml"
    "k8s_bkp/pxb_volumesnapshotdatas.txt"
    "k8s_bkp/pxb_volumesnapshotdatas.yaml"
    "k8s_bkp/pxb_volumesnapshotschedules.txt"
    "k8s_bkp/pxb_volumesnapshotschedules.yaml"
    "k8s_bkp/pxb_volumesnapshotrestores.txt"
    "k8s_bkp/pxb_volumesnapshotrestores.yaml"
    "k8s_bkp/pxb_schedulepolicies.txt"
    "k8s_bkp/pxb_schedulepolicies.yaml"

  )
  pxctl_commands=(
    "status"
    "status -j"
    "cluster provision-status"
    "license list"
    "cluster options list"
    "cluster options list -j"
    "sv k m"
    "alerts show"
    "cloudsnap status"
    "cloudsnap status -j"
    "cd list"
    "cd list -j"
    "cred list"
    "volume list -v"
    "volume list -v -j"
    "volume list -s"
    "volume list -s -j"

  )
  pxctl_output_files=(
    "px_out/pxctl_status.txt"
    "px_out/pxctl_status.json"
    "px_out/pxctl_cluster_provision_status.txt"
    "px_out/pxctl_license_list.txt"
    "px_out/pxctl_cluster_options.txt"
    "px_out/pxctl_cluster_options.json"
    "px_out/pxctl_kvdb_members.txt"
    "px_out/pxctl_alerts_show.txt"
    "px_out/pxctl_cs_status.txt"
    "px_out/pxctl_cs_status.json"
    "px_out/pxctl_cd_list.txt"
    "px_out/pxctl_cd_list.json"
    "px_out/pxctl_cred_list.txt"
    "px_out/pxctl_volume_list.txt"
    "px_out/pxctl_volume_list.json"
    "px_out/pxctl_volume_snapshot_list.txt"
    "px_out/pxctl_volume_snapshot_list.json"
    
  )

  log_labels=(
    "name=autopilot"
    "name=portworx-api"
    "name=portworx-operator"
    "app=px-csi-driver"
    "name=stork"
    "name=stork-scheduler"
    "name=portworx-pvc-controller"
    "role=px-telemetry-registration"
    "name=px-telemetry-phonehome"
    "app=px-plugin"
    "name=px-plugin-proxy"
  )

  oth_commands=(
    "$cli -n kube-system get cm $($cli -n kube-system get cm|grep px-bootstrap|awk '{print $1}') -o yaml"
    "$cli -n kube-system get cm $($cli -n kube-system get cm|grep px-bootstrap|awk '{print $1}') -o json"
    "$cli -n kube-system get cm $($cli -n kube-system get cm|grep px-cloud-drive|awk '{print $1}') -o yaml"
    "$cli -n kube-system get cm $($cli -n kube-system get cm|grep px-cloud-drive|awk '{print $1}') -o json"

  )
  oth_output_files=(
    "k8s_px/px-bootstrap.yaml"
    "k8s_px/px-bootstrap.json"
    "k8s_px/px-cloud-drive.yaml"
    "k8s_px/px-cloud-drive.json"

  )
  migration_commands=(
    "get clusterpair -n $admin_ns"
    "describe clusterpair -n $admin_ns "
    "get clusterpair -n $admin_ns -o yaml"
    "get migrations -n $admin_ns"
    "describe migrations -n $admin_ns"
    "get migrations -n $admin_ns -o yaml"
    "get migrationschedule -n $admin_ns"
    "get migrationschedule -n $admin_ns -o yaml"
    "get schedulepolicies"
    "get schedulepolicies -o yaml"
  )
   migration_output=(
    "migration/clusterpair.txt"
    "migration/clusterpair_desc.txt"
    "migration/clusterpair.yaml"
    "migration/migrations.txt"
    "migration/migrations_desc.txt"
    "migration/migrations.yaml"
    "migration/migrationschedule.txt"
    "migration/migrationschedule.yaml"
    "migration/schedulepolicies.txt"
    "migration/schedulepolicies.yaml"
  )

   kubevirt_commands=(
    "get kubevirts -A"
    "get kubevirts -A -o yaml"
    "get virtualmachines -A"
    "get virtualmachines -A -o yaml"
    "get virtualmachineinstances -A"
    "get virtualmachineinstances -A -o yaml"
    "get hyperconvergeds -A"
    "get hyperconvergeds -A -o yaml"
    "get cdiconfigs"
    "get cdiconfigs -o yaml"
    "get cdis"
    "get cdis -o yaml"
    "get datavolumes -A"
    "get datavolumes -A -o yaml"
    "describe datavolumes -A"
    "get storageprofiles"
    "get storageprofiles -o yaml"
    "get migrations.forklift.konveyor.io -A"
    "get migrations.forklift.konveyor.io -A -o yaml"
  )
  
   kubevirt_output=(
    "k8s_oth/kubevirts_list.txt"
    "k8s_oth/kubevirts.yaml"
    "k8s_oth/kubevirt_virtualmachines.txt"
    "k8s_oth/kubevirt_virtualmachines.yaml"
    "k8s_oth/kubevirt_virtualmachineinstances.txt"
    "k8s_oth/kubevirt_virtualmachineinstances.yaml"
    "k8s_oth/kubevirt_hyperconvergeds.txt"
    "k8s_oth/kubevirt_hyperconvergeds.yaml"
    "k8s_oth/kubevirt_kubevirt_cdiconfigs.txt"
    "k8s_oth/kubevirt_cdiconfigs.yaml"
    "k8s_oth/kubevirt_cdis.txt"
    "k8s_oth/kubevirt_cdis.yaml"
    "k8s_oth/kubevirt_datavolumes.txt"
    "k8s_oth/kubevirt_datavolumes.yaml"
    "k8s_oth/kubevirt_datavolumes_desc.txt"
    "k8s_oth/kubevirt_storageprofiles.txt"
    "k8s_oth/kubevirt_storageprofiles.yaml"
    "k8s_oth/kubevirt_migrations_list.txt"
    "k8s_oth/kubevirt_migrations.yaml"
  )
  
  logs_oth_ns=()

  main_dir="PX_${namespace}_outputs_$(date +%Y%m%d_%H%M%S)"
  output_dir="/tmp/${main_dir}"
  sub_dir=(${output_dir}/logs ${output_dir}/px_out ${output_dir}/k8s_px ${output_dir}/k8s_oth ${output_dir}/migration ${output_dir}/k8s_pxb)
else
  commands=(
    "get pods -o wide -n $namespace"
    "get pods -o wide -n $namespace -o yaml"
    "describe pods -n $namespace"
    "get nodes -o wide -n $namespace"
    "get nodes -o wide -n $namespace -o yaml"
    "describe nodes -n $namespace"
    "get events -A --sort-by=.lastTimestamp"
    "get deploy -o wide -n $namespace"
    "get deploy -o wide -n $namespace -o yaml"
    "describe deploy -n $namespace"
    "get sts -o wide -n $namespace"
    "get sts -o wide -n $namespace -o yaml"
    "describe sts -n $namespace"
    "get csidrivers"
    "get csinodes"
    "get csinodes -o yaml"
    "get all -o wide -n $namespace"
    "describe all -n $namespace"
    "get all -o wide -n $namespace -o yaml"
    "get configmaps -n $namespace"
    "describe namespace $namespace"
    "get namespace $namespace -o yaml"
    "get pvc -n $namespace"
    "get pvc -n $namespace -o yaml"
    "get cm -o yaml -n $namespace"
    "get job,cronjobs -o wide -n $namespace"
    "get applicationbackups -A"
    "get applicationbackups -A -o yaml"
    "get applicationbackupschedule -A"
    "get applicationbackupschedule -A -o yaml"
    "get applicationrestores -A"
    "get applicationrestores -A -o yaml"
    "get applicationregistrations -A"
    "get applicationregistrations -A -o yaml"
    "get backuplocations -A"
    "get backuplocations -A -o yaml"
    "get volumesnapshots -A"
    "get volumesnapshots -A -o yaml"
    "get volumesnapshotcontents"
    "get volumesnapshotcontents -o yaml"
    "get volumesnapshotdatas -A"
    "get volumesnapshotdatas -A -o yaml"
    "get volumesnapshotschedules -A"
    "get volumesnapshotschedules -A -o yaml"
    "get volumesnapshotrestores -A"
    "get volumesnapshotrestores -A -o yaml"
    "get schedulepolicies"
    "get schedulepolicies -o yaml"
    "get sc"
    "get sc -o yaml"
    "get pvc -A"
    "get pv"
    "get dataexports -A"
    "get mutatingwebhookconfiguration"
    "get mutatingwebhookconfiguration -o yaml"
    "get cm kdmp-config -n kube-system -o yaml"
 )
 output_files=(
    "k8s_pxb/pxb_pods.txt"
    "k8s_pxb/pxb_pods.yaml"
    "k8s_pxb/pxb_pods_desc.txt"
    "k8s_oth/k8s_nodes.txt"
    "k8s_oth/k8s_nodes.yaml"
    "k8s_oth/k8s_nodes_desc.txt"
    "k8s_oth/k8s_events_all.txt"
    "k8s_pxb/pxb_deploy.txt"
    "k8s_pxb/pxb_deploy.yaml"
    "k8s_pxb/pxb_deploy_desc.txt"
    "k8s_pxb/pxb_sts.txt"
    "k8s_pxb/pxb_sts.yaml"
    "k8s_pxb/pxb_sts_desc.txt"
    "k8s_oth/csidrivers.txt"
    "k8s_oth/csinodes.txt"
    "k8s_oth/csinodes.yaml"
    "k8s_pxb/pxb_all.txt"
    "k8s_pxb/pxb_all_desc.txt"
    "k8s_pxb/pxb_all.yaml"
    "k8s_pxb/pxb_cm.txt"
    "k8s_pxb/pxb_ns_dec.txt"
    "k8s_pxb/pxb_ns_dec.yaml"
    "k8s_pxb/pxb_pvc.txt"
    "k8s_pxb/pxb_pvc.yaml"
    "k8s_pxb/pxb_cm.yaml" 
    "k8s_pxb/pxb_job_cronjob.txt"
    "k8s_bkp/pxb_applicationbackups.txt"
    "k8s_bkp/pxb_applicationbackups.yaml"
    "k8s_bkp/pxb_applicationbackupschedules.txt"
    "k8s_bkp/pxb_applicationbackupschedules.yaml"
    "k8s_bkp/pxb_applicationrestores.txt"
    "k8s_bkp/pxb_applicationrestores.yaml"
    "k8s_bkp/pxb_applicationregistrations.txt"
    "k8s_bkp/pxb_applicationregistrations.yaml"
    "k8s_bkp/pxb_backuplocations.txt"
    "k8s_bkp/pxb_backuplocations.yaml"
    "k8s_bkp/pxb_volumesnapshots.txt"
    "k8s_bkp/pxb_volumesnapshots.yaml"
    "k8s_bkp/pxb_volumesnapshotcontents.txt"
    "k8s_bkp/pxb_volumesnapshotcontents.yaml"
    "k8s_bkp/pxb_volumesnapshotdatas.txt"
    "k8s_bkp/pxb_volumesnapshotdatas.yaml"
    "k8s_bkp/pxb_volumesnapshotschedules.txt"
    "k8s_bkp/pxb_volumesnapshotschedules.yaml"
    "k8s_bkp/pxb_volumesnapshotrestores.txt"
    "k8s_bkp/pxb_volumesnapshotrestores.yaml"
    "k8s_bkp/pxb_schedulepolicies.txt"
    "k8s_bkp/pxb_schedulepolicies.yaml"
    "k8s_oth/sc.txt"
    "k8s_oth/sc.yaml"
    "k8s_oth/pvc_list.txt"
    "k8s_oth/pv_list.txt"
    "k8s_bkp/pxb_dataexports.txt"
    "k8s_oth/mutatingwebhookconfiguration.txt"
    "k8s_oth/mutatingwebhookconfiguration.yaml"
    "k8s_pxb/kdmp-config.yaml"
  )
log_labels=(
  ""
)
migration_commands=()
oth_commands=()
logs_oth_ns=(
    "name=stork"
    "kdmp.portworx.com/driver-name=kopiabackup"
    "kdmp.portworx.com/driver-name=nfsbackup"
)

  main_dir="PX_Backup_${namespace}_outputs_$(date +%Y%m%d_%H%M%S)"
  output_dir="/tmp/${main_dir}"
  sub_dir=(${output_dir}/logs ${output_dir}/k8s_pxb ${output_dir}/k8s_oth ${output_dir}/k8s_bkp)

fi

# Create a temporary directory for storing outputs
mkdir -p "$output_dir"
mkdir -p "${sub_dir[@]}"
echo "$(date '+%Y-%m-%d %H:%M:%S'): Output will be stored in: $output_dir"
echo "$(date '+%Y-%m-%d %H:%M:%S'): Extraction is started"

#Generate Summary file with parameter and date information
summary_file=$output_dir/Summary.txt
echo "Namespace: $namespace">$summary_file
echo "CLI tool: $cli">>$summary_file
echo "option: $option">>$summary_file
echo "Start of generation:" $(date)>>$summary_file

# Execute commands and save outputs to files
print_progress 1
for i in "${!commands[@]}"; do
  cmd="${commands[$i]}"
  output_file="$output_dir/${output_files[$i]}"
  #echo "Executing: $cli $cmd"
  $cli $cmd > "$output_file" 2>&1
  #echo "Output saved to: $output_file"
  #echo ""
  #echo "------------------------------------" 
done

   if [ "$sec_enabled" == "true" ]; then
     TOKEN_EXP="export PXCTL_AUTH_TOKEN=$($cli -n $namespace get secret px-admin-token --template='{{index .data "auth-token" | base64decode}}')"
     echo "Security Enabled: true">>$summary_file
     #pxcmd="exec service/portworx-service -- bash -c \"\${TOKEN} && /opt/pwx/bin/pxctl"
     #pxcmd="exec service/portworx-service -- bash -c \"${TOKEN} && /opt/pwx/bin/pxctl"

  else
     echo "Security Enabled: false">>$summary_file
     #pxcmd="exec service/portworx-service -- \"/opt/pwx/bin/pxctl"
  fi
# Execute pxctl commands 
print_progress 2

for i in "${!pxctl_commands[@]}"; do
  cmd="${pxctl_commands[$i]}"
  output_file="$output_dir/${pxctl_output_files[$i]}"
  #echo "Executing: pxctl $cmd"
  #final_px_command="$pxcmd $cmd\""
  #echo $final_px_command
  if [ "$sec_enabled" == "true" ]; then
  $cli -n $namespace exec service/portworx-service -- bash -c "${TOKEN_EXP} && /opt/pwx/bin/pxctl $cmd" > "$output_file" 2>&1
  else
  $cli -n $namespace exec service/portworx-service -- bash -c "/opt/pwx/bin/pxctl $cmd" > "$output_file" 2>&1
  fi
  #$cli -n $namespace $final_px_command > "$output_file" 2>&1
  #echo "Output saved to: $output_file"
  #echo ""
  #echo "------------------------------------" 
done

# Generating Logs
print_progress 3

for i in "${!log_labels[@]}"; do
  label="${log_labels[$i]}"
  if [[ "$option" == "PX" ]]; then
    PODS=$($cli get pods -n $namespace -l $label -o jsonpath="{.items[*].metadata.name}")
  else
    PODS=$($cli get pods -n $namespace -o jsonpath="{.items[*].metadata.name}")
  fi
  for POD in $PODS; do
  LOG_FILE="${output_dir}/logs/${POD}.log"
  #echo "Fetching logs for pod: $POD"
  # Fetch logs and write to file
  $cli logs -n "$namespace" "$POD" --tail -1 --all-containers > "$LOG_FILE"
  done
  #echo "Logs for pod $POD written to: $LOG_FILE"
done

# Execute other commands 
print_progress 4

for i in "${!oth_commands[@]}"; do
  cmd="${oth_commands[$i]}"
  output_file="$output_dir/${oth_output_files[$i]}"
  #echo "Executing:  $cmd"
  $cmd > "$output_file" 2>&1
  #echo "Output saved to: $output_file"
  #echo ""
  #echo "------------------------------------" 
done

#Check if kubevirt is enabled and get kubevirt configs only if kubevirt is enabled
print_progress 5

if $cli get crd | grep -q "virtualmachines.kubevirt.io"; then
  #echo "KubeVirt is likely enabled."
  mkdir -p $output_dir
  for i in "${!kubevirt_commands[@]}"; do
    cmd="${kubevirt_commands[$i]}"
    output_file="$output_dir/${kubevirt_output[$i]}"
    $cli $cmd > "$output_file" 2>&1
  done
fi

#Execute Migration commands

print_progress 6

for i in "${!migration_commands[@]}"; do
  cmd="${migration_commands[$i]}"
  output_file="$output_dir/${migration_output[$i]}"
  #echo "Executing: $cli $cmd"
  $cli $cmd > "$output_file" 2>&1
  #echo "Output saved to: $output_file"
  #echo ""
  #echo "------------------------------------" 
done

#Execute log extractions from other namespaces

print_progress 7

for i in "${!logs_oth_ns[@]}"; do
  label="${logs_oth_ns[$i]}"
  $cli get pods -A -l $label -o jsonpath="{range .items[*]}{.metadata.namespace} {.metadata.name}{'\n'}{end}"|
  while read -r namespace pod; do  
  if [[ -n "$namespace" && -n "$pod" ]]; then
        LOG_FILE="${output_dir}/logs/${pod}.log"
        if [[ "$option" == "PXB" ]]; then
        POD_YAML_FILE="${output_dir}/k8s_pxb/${pod}.yaml"
        else
        POD_YAML_FILE="${output_dir}/k8s_px/${pod}.yaml"
        fi
        #echo "Saving logs for Pod: $pod (Namespace: $namespace)"
        $cli logs -n "$namespace" "$pod" --tail -1 --all-containers > "$LOG_FILE"
        $cli -n "$namespace" get pod "$pod" -o yaml > "$POD_YAML_FILE"
  fi
  
  done
done

echo "$(date '+%Y-%m-%d %H:%M:%S'): Extraction is completed"
echo "End of generation:" $(date)>>$summary_file

# Compress the output directory into a tar file
archive_file="${main_dir}.tar"
cd /tmp
tar -cf "$archive_file" "$main_dir"
echo "************************************************"
echo ""
echo "$(date '+%Y-%m-%d %H:%M:%S'): All outputs compressed into: /tmp/$archive_file"
echo ""
echo "************************************************"

# Delete the temporary op directory 
if [[ -d "$output_dir" ]]; then
  rm -rf "$output_dir"
  echo ""
else
  echo ""
fi

echo "$(date '+%Y-%m-%d %H:%M:%S'): Script execution completed successfully."
