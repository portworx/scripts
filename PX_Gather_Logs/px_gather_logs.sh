#!/bin/bash
# ================================================================
# Script: px_gather_logs.sh
# Description: Collects logs and other information related to portworx/PX Backup.
# Usage:
# - We can pass the inputs as parameters like below
#   For Portworx : px_gather_logs.sh -n <Portworx namespace> -c <k8s cli> -o PX
#       Example: px_gather_logs.sh -n portworx -c kubectl -o PX
#   For PX Backup: px_gather_logs.sh -n <Portworx Backup namespace> -c <k8s cli> -o PXB
#       Example: px_gather_logs.sh -n px-backup -c oc -o PXB
# - If there are no parameters passed, shell will prompt for input
#
# ================================================================

SCRIPT_VERSION="25.6.0"

# Function to display usage
usage() {
  echo "Usage: $0 [-n <namespace>] [-c <cli>] [-o <option>]"
  echo "  -n <namespace> : Kubernetes namespace"
  echo "  -c <cli>       : CLI tool to use (oc/kubectl)"
  echo "  -o <option>    : Operation option (PX/PXB)"
  exit 1
}
# Function to print info in summary file

log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $*" >> $summary_file
}

# Function to print progress

print_progress() {
    local current_stage=$1
    local total_stages="7"
    echo "$(date '+%Y-%m-%d %H:%M:%S'): Extracting $current_stage/$total_stages..." | tee -a "$summary_file"
}

# Parse command-line arguments
while getopts "n:c:o:u:p:" opt; do
  case $opt in
    n) namespace=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]') ;;
    c) cli="$OPTARG" ;;
    o) option=$(echo "$OPTARG" | tr '[:lower:]' '[:upper:]') ;;
    u) ftpsuser=$(echo "$OPTARG" | tr '[:lower:]' '[:upper:]') ;;
    p) ftpspass="$OPTARG" ;;
    *) usage ;;
  esac
done

# Prompt for namespace if not provided
if [[ -z "$namespace" ]]; then
  read -p "Enter the namespace: " namespace && namespace=${namespace,,}
  if [[ -z "$namespace" ]]; then
    echo "Error: Namespace cannot be empty."
    exit 1
  fi
fi



# Prompt for k8s CLI  if not provided
if [[ -z "$cli" ]]; then
  read -p "Enter the k8s CLI (oc/kubectl): " cli
fi

# Check if the CLI value is kubectl or OC

if [[ "$cli" != "oc" && "$cli" != "kubectl" ]]; then
  echo "Error: Invalid k8s CLI. Choose either 'oc' or 'kubectl'."
  exit 1
fi

# Check if the CLI is available
if ! command -v "$cli" &> /dev/null; then
  echo "Error: '$cli' command not found. Please ensure that '$cli' is available in this server"
  exit 1
fi

# Check if the CLI command works
if ! $cli cluster-info &> /dev/null; then
  echo "Error: '$cli' is available but not functioning correctly. Ensure you have the necessary permissions to execute '$cli' commands on the cluster."
  exit 1
fi



# Prompt for option if not provided
if [[ -z "$option" ]]; then
  read -p "Choose an option (PX/PXB) (Enter PX for Portworx Enterprise/CSI, Enter PXB for PX Backup): " option && option=${option^^}
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
  admin_ns=$($cli -n $namespace get stc -o jsonpath='{.items[*].spec.stork.args.admin-namespace}')
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
    "get configmaps -n $namespace"
    "describe namespace $namespace"
    "get namespace $namespace -o yaml"
    "get pvc -n $namespace"
    "get pvc -n $namespace -o yaml"
    "get secret -n $namespace"
    "get sc"
    "get sc -o yaml"
    "get pvc -A"
    "get pvc -A -o yaml"
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
    "api-resources"
    "get autopilotrules"
    "get autopilotrules -o yaml"
    "get autopilotruleobjects -A"
    "get autopilotruleobjects -A -o yaml"
    "get applicationbackups -A"
    "get applicationbackups -A -o yaml"
    "get applicationbackupschedule -A"
    "get applicationbackupschedule -A -o yaml"
    "describe applicationbackupschedule -A"
    "get applicationrestores -A"
    "get applicationrestores -A -o yaml"
    "describe applicationrestores -A"
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
    "get volumesnapshotclasses"
    "get volumesnapshotclasses -o yaml"
    "get schedulepolicies"
    "get schedulepolicies -o yaml"
    "get dataexports -A"
    "get prometheuses -A"
    "get prometheuses -A -o yaml"
    "get prometheusrules -A"
    "get prometheusrules -A -o yaml"
    "get alertmanagers -A"
    "get alertmanagers -A -o yaml" 
    "get alertmanagerconfigs -A"
    "get alertmanagerconfigs -A -o yaml" 
    "get servicemonitors -A"
    "get servicemonitors -A -o yaml"
    "get mutatingwebhookconfiguration"
    "get mutatingwebhookconfiguration -o yaml"
    "get cm kdmp-config -n kube-system -o yaml"
    "get rules -A"
    "get rules -A -o yaml"
    "get svc,ep -A -l "portworx.io/volid" -o wide"
    "get svc,ep -A -l "portworx.io/volid" -o yaml"
    "get pods -A -o wide"
    
    
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
    "k8s_px/px_cm.txt"
    "k8s_px/px_ns_dec.txt"
    "k8s_px/px_ns_dec.yaml"
    "k8s_px/px_pvc.txt"
    "k8s_px/px_pvc.yaml"
    "k8s_px/px_secret_list.txt"
    "k8s_oth/sc.txt"
    "k8s_oth/sc.yaml"
    "k8s_oth/pvc_list.txt"
    "k8s_oth/pvc_all.yaml"
    "k8s_oth/pv_list.txt"
    "k8s_px/px_storagenodes_list.txt"
    "k8s_oth/mutatingwebhookconfiguration.txt"
    "k8s_oth/mutatingwebhookconfiguration.yaml"
    "k8s_px/px_svc_ep.txt"
    "k8s_px/px_svc_ep.yaml"
    "k8s_px/px_ds.yaml"
    "k8s_px/px_pdb.txt"
    "k8s_px/px_pdb.yaml"
    "k8s_oth/pods_kube_system.txt"
    "k8s_oth/k8s_version.txt"
    "k8s_oth/k8s_api_resources.txt"
    "k8s_px/autopilotrules.txt"
    "k8s_px/autopilotrules.yaml"
    "k8s_px/autopilotruleobjects.txt"
    "k8s_px/autopilotruleobjects.yaml"
    "k8s_bkp/pxb_applicationbackups.txt"
    "k8s_bkp/pxb_applicationbackups.yaml"
    "k8s_bkp/pxb_applicationbackupschedules.txt"
    "k8s_bkp/pxb_applicationbackupschedules.yaml"
    "k8s_bkp/pxb_applicationbackupschedules_desc.txt"
    "k8s_bkp/pxb_applicationrestores.txt"
    "k8s_bkp/pxb_applicationrestores.yaml"
    "k8s_bkp/pxb_applicationrestores_desc.txt"
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
    "k8s_bkp/volumesnapshotclasses.txt"
    "k8s_bkp/volumesnapshotclasses.yaml"
    "k8s_bkp/pxb_schedulepolicies.txt"
    "k8s_bkp/pxb_schedulepolicies.yaml"  
    "k8s_bkp/pxb_dataexports.txt"
    "k8s_oth/prometheuses_list.txt"
    "k8s_oth/prometheuses.yaml"
    "k8s_oth/prometheuses_rules_list.txt"
    "k8s_oth/prometheuses_rules.yaml"
    "k8s_oth/alertmanagers_list.txt"
    "k8s_oth/alertmanagers.yaml"
    "k8s_oth/alertmanagerconfigs.txt"
    "k8s_oth/alertmanagerconfigs.yaml"
    "k8s_oth/servicemonitors.txt"
    "k8s_oth/servicemonitors.yaml"  
    "k8s_oth/mutatingwebhookconfiguration.txt"
    "k8s_oth/mutatingwebhookconfiguration.yaml"
    "k8s_pxb/kdmp-config.yaml"
    "k8s_bkp/px_rules.txt"
    "k8s_bkp/px_rules.yaml"
    "k8s_px/px_sharedv4_svc_ep.txt"
    "k8s_px/px_sharedv4_svc_ep.yaml"
    "k8s_oth/pods_all.txt"

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
    "name=portworx"
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
    "get migrations.stork.libopenstorage.org -n $admin_ns"
    "describe migrations.stork.libopenstorage.org -n $admin_ns"
    "get migrations.stork.libopenstorage.org -n $admin_ns -o yaml"
    "get migrationschedule -n $admin_ns"
    "get migrationschedule -n $admin_ns -o yaml"
    "get schedulepolicies"
    "get schedulepolicies -o yaml"
    "get clusterdomainsstatuses"
    "get clusterdomainsstatuses -o yaml"
    "get resourcetransformations -A"
    "get resourcetransformations -A -o yaml"
  )
   migration_output=(
    "migration/clusterpair.txt"
    "migration/migrations.txt"
    "migration/migrations_desc.txt"
    "migration/migrations.yaml"
    "migration/migrationschedule.txt"
    "migration/migrationschedule.yaml"
    "migration/schedulepolicies.txt"
    "migration/schedulepolicies.yaml"
    "migration/cds.txt"
    "migration/cds.yaml"
    "migration/resourcetransformations.txt"
    "migration/resourcetransformations.yaml"
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
    "get virtualmachinerestore -A"
    "get virtualmachinerestore -A -o yaml"
    "describe virtualmachinerestore -A"
    "get pods -l kubevirt.io=virt-launcher -A"
    "get pods -l kubevirt.io=virt-launcher -A -o yaml"
  )
  
   kubevirt_output=(
    "kubevirt/kubevirts_list.txt"
    "kubevirt/kubevirts.yaml"
    "kubevirt/kubevirt_virtualmachines.txt"
    "kubevirt/kubevirt_virtualmachines.yaml"
    "kubevirt/kubevirt_virtualmachineinstances.txt"
    "kubevirt/kubevirt_virtualmachineinstances.yaml"
    "kubevirt/kubevirt_hyperconvergeds.txt"
    "kubevirt/kubevirt_hyperconvergeds.yaml"
    "kubevirt/kubevirt_kubevirt_cdiconfigs.txt"
    "kubevirt/kubevirt_cdiconfigs.yaml"
    "kubevirt/kubevirt_cdis.txt"
    "kubevirt/kubevirt_cdis.yaml"
    "kubevirt/kubevirt_datavolumes.txt"
    "kubevirt/kubevirt_datavolumes.yaml"
    "kubevirt/kubevirt_datavolumes_desc.txt"
    "kubevirt/kubevirt_storageprofiles.txt"
    "kubevirt/kubevirt_storageprofiles.yaml"
    "kubevirt/kubevirt_migrations_list.txt"
    "kubevirt/kubevirt_migrations.yaml"
    "kubevirt/kubevirt_vmrestore.txt"
    "kubevirt/kubevirt_vmrestore.yaml"
    "kubevirt/kubevirt_vmrestore_desc.txt"
    "kubevirt/kubevirt_virt_launcher_pods.txt"
    "kubevirt/kubevirt_virt_launcher_pods.yaml"
  )
  
  logs_oth_ns=()

  main_dir="PX_${namespace}_k8s_diags_$(date +%Y%m%d_%H%M%S)"
  output_dir="/tmp/${main_dir}"
  sub_dir=(${output_dir}/logs ${output_dir}/px_out ${output_dir}/k8s_px ${output_dir}/k8s_oth ${output_dir}/migration ${output_dir}/k8s_bkp ${output_dir}/k8s_pxb)
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
    "get job,cronjobs -n $namespace -o yaml"
    "describe job,cronjobs -n $namespace"
    "get applicationbackups -A"
    "get applicationbackups -A -o yaml"
    "get applicationbackupschedule -A"
    "get applicationbackupschedule -A -o yaml"
    "describe applicationbackupschedule -A"
    "get applicationrestores -A"
    "get applicationrestores -A -o yaml"
    "describe applicationrestores -A"
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
    "get volumesnapshotclasses"
    "get volumesnapshotclasses -o yaml"
    "get schedulepolicies"
    "get schedulepolicies -o yaml"
    "get sc"
    "get sc -o yaml"
    "get pvc -A"
    "get pvc -A -o yaml"
    "get pv"
    "get dataexports -A"
    "get prometheuses -A"
    "get prometheuses -A -o yaml"
    "get prometheusrules -A"
    "get prometheusrules -A -o yaml"
    "get alertmanagers -A"
    "get alertmanagers -A -o yaml" 
    "get alertmanagerconfigs -A"
    "get alertmanagerconfigs -A -o yaml" 
    "get servicemonitors -A"
    "get servicemonitors -A -o yaml"
    "get mutatingwebhookconfiguration"
    "get mutatingwebhookconfiguration -o yaml"
    "get cm kdmp-config -n kube-system -o yaml"
    "version"
    "api-resources"
    "get ns"
    "get ns -o yaml"
    "get secret -n $namespace"
    "get pods -A -o wide"
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
    "k8s_pxb/pxb_job_cronjob.yaml"
    "k8s_pxb/pxb_job_cronjob_desc.txt"
    "k8s_bkp/pxb_applicationbackups.txt"
    "k8s_bkp/pxb_applicationbackups.yaml"
    "k8s_bkp/pxb_applicationbackupschedules.txt"
    "k8s_bkp/pxb_applicationbackupschedules.yaml"
    "k8s_bkp/pxb_applicationbackupschedules_desc.txt"
    "k8s_bkp/pxb_applicationrestores.txt"
    "k8s_bkp/pxb_applicationrestores.yaml"
    "k8s_bkp/pxb_applicationrestores_desc.txt"
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
    "k8s_bkp/volumesnapshotclasses.txt"
    "k8s_bkp/volumesnapshotclasses.yaml"
    "k8s_bkp/pxb_schedulepolicies.txt"
    "k8s_bkp/pxb_schedulepolicies.yaml"
    "k8s_oth/sc.txt"
    "k8s_oth/sc.yaml"
    "k8s_oth/pvc_list.txt"
    "k8s_oth/pvc_all.yaml"
    "k8s_oth/pv_list.txt"
    "k8s_bkp/pxb_dataexports.txt"
    "k8s_oth/prometheuses_list.txt"
    "k8s_oth/prometheuses.yaml"
    "k8s_oth/prometheuses_rules_list.txt"
    "k8s_oth/prometheuses_rules.yaml"
    "k8s_oth/alertmanagers_list.txt"
    "k8s_oth/alertmanagers.yaml"
    "k8s_oth/alertmanagerconfigs.txt"
    "k8s_oth/alertmanagerconfigs.yaml"
    "k8s_oth/servicemonitors.txt"
    "k8s_oth/servicemonitors.yaml"  
    "k8s_oth/mutatingwebhookconfiguration.txt"
    "k8s_oth/mutatingwebhookconfiguration.yaml"
    "k8s_pxb/kdmp-config.yaml"
    "k8s_oth/k8s_version.txt"
    "k8s_oth/k8s_api_resources.txt"
    "k8s_oth/ns.txt"
    "k8s_oth/ns.yaml"
    "k8s_pxb/pxb_secret_list.txt"
    "k8s_oth/pods_all.txt"
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

  main_dir="PX_Backup_${namespace}_k8s_diags_$(date +%Y%m%d_%H%M%S)"
  output_dir="/tmp/${main_dir}"
  sub_dir=(${output_dir}/logs ${output_dir}/k8s_pxb ${output_dir}/k8s_oth ${output_dir}/k8s_bkp)

fi

# Common extracts applicable for all 

  k8s_log_labels=(
    "component=kube-apiserver"
    "component=kube-scheduler"
    "component=etcd"
    "component=kube-controller-manager"
  )

# Create a temporary directory for storing outputs
mkdir -p "$output_dir"
mkdir -p "${sub_dir[@]}"
echo "$(date '+%Y-%m-%d %H:%M:%S'): Output will be stored in: $output_dir"
echo "$(date '+%Y-%m-%d %H:%M:%S'): Extraction is started"

#Generate Summary file with parameter and date information
summary_file=$output_dir/Summary.txt
log_info "Script version: $SCRIPT_VERSION"
log_info "Namespace: $namespace"
log_info "CLI tool: $cli"
log_info "option: $option"
log_info "Security Enabled: ${sec_enabled:-false}"
log_info "Extraction Started"


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
     #echo "Security Enabled: true">>$summary_file
     #pxcmd="exec service/portworx-service -- bash -c \"\${TOKEN} && /opt/pwx/bin/pxctl"
     #pxcmd="exec service/portworx-service -- bash -c \"${TOKEN} && /opt/pwx/bin/pxctl"

  #else
     #echo "Security Enabled: false">>$summary_file
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
    log_count=0
  else
    PODS=$($cli get pods -n $namespace -o jsonpath="{.items[*].metadata.name}")
  fi
  for POD in $PODS; do
  LOG_FILE="${output_dir}/logs/${POD}.log"

  if [[ "$label" == "name=portworx" ]]
  then
     max_logs=5
     if [[ $log_count -lt $max_logs ]]
     then
        #echo "log_count- $log_count max_logs: $max_logs pod: $POD"
        $cli get pod -n "$namespace" "$POD" -o custom-columns=":.status.containerStatuses[*].ready" --no-headers | grep -q "false"
        if [[ $? -eq 0 ]]
        then
           #echo "Found non-ready container in pod: $pod"
           $cli logs -n "$namespace" "$POD" --tail -1 --all-containers > "$LOG_FILE"
           ((log_count++))
        fi
     fi
  else
  #echo "Fetching logs for pod: $POD"
  # Fetch logs and write to file
  $cli logs -n "$namespace" "$POD" --tail -1 --all-containers > "$LOG_FILE"
  fi
  done
  #echo "Logs for pod $POD written to: $LOG_FILE"
done

for i in "${!k8s_log_labels[@]}"; do
  label="${k8s_log_labels[$i]}"
  PODS=$($cli get pods -n kube-system -l $label -o jsonpath="{.items[*].metadata.name}")
  for POD in $PODS; do
  LOG_FILE="${output_dir}/logs/${POD}.log"
  #echo "Fetching logs for pod: $POD"
  # Fetch logs and write to file
  $cli logs -n kube-system "$POD" --tail -1 --all-containers > "$LOG_FILE"
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
  mkdir -p $output_dir/kubevirt
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
log_info "Extraction is completed"

# Compress the output directory into a tar file
archive_file="${main_dir}.tar.gz"
cd /tmp
tar -czf "$archive_file" "$main_dir"
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

#Uploags to FTPS if FTPS credentails are provided with -u username and -p password
if [[ -n "$ftpsuser" && -n "$ftpspass" ]]; then
  echo "FTPS credentials are provided as Argument. Uploading to FTPS directly"
  ftpshost="https://ftps.purestorage.com"
  ftps_connection_response=$(curl -Is "$ftpshost" -u "$ftpsuser:$ftpspass" -o /dev/null -w "%{http_code}\n")

  if [[ "$ftps_connection_response" -eq 200 ]]; then
    echo "FTPS connection successful."
    echo "Executing: curl --ftp-ssl --ftp-port 443 -u <username>:<password> -T \"/tmp/$archive_file\" \"$ftpshost/\""
    curl --ftp-ssl --ftp-port 443 -u $ftpsuser:$ftpspass -T /tmp/$archive_file "$ftpshost"
    if [ $? -eq 0 ]; then
      echo "Successfully uploaded to FTPS - $ftpshost"
      else
        echo "Error: Problem in uploading. Upload failed/partial"
    fi
  elif [[ "$ftps_connection_response" -eq 401 ]]; then
    echo "FTPS connection successful, but credentials provided look incorrect. Please get updated credentials or upload the generated log file manually over case"
  else
    echo "FTPS connection check failed. Please provide the output file /tmp/$archive_file over case"
  fi
fi

echo "$(date '+%Y-%m-%d %H:%M:%S'): Script execution completed successfully."
