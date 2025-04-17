# px_gather_logs.sh

## Description
Collects logs and other information related to Portworx/PX Backup for issue analysis. This can be executed from any unix-based terminal where we have kubectl/oc command access to the cluster. Script will generate a tarball file in /tmp folder

## Usage
### Passing Inputs as Parameters
#### For Portworx:
```bash
px_gather_logs.sh -n <Portworx namespace> -c <k8s cli> -o PX
```
Example:
```bash
px_gather_logs.sh -n portworx -c kubectl -o PX
```

#### For PX Backup:
```bash
px_gather_logs.sh -n <Portworx Backup namespace> -c <k8s cli> -o PXB
```
Example:
```bash
px_gather_logs.sh -n px-backup -c oc -o PXB
```

### Without Parameters
If no parameters are passed, the script will prompt for input.
````bash
./px_gather_logs.sh 
Enter the namespace: portworx
Enter the k8s CLI  (oc/kubectl): kubectl
Choose an option (PX/PXB) (Enter PX for Portworx Enterprise/CSI, Enter PXB for PX Backup): PX
````

### Execute Using Curl
You can download and execute the script directly from GitHub using the following command:
```bash
curl -ssL https://raw.githubusercontent.com/portworx/scripts/refs/heads/main/PX_Gather_Logs/px_gather_logs.sh | bash -s -- -n <namespace> -c <kubectl/oc> -o <PX/PXB>
```
Example:
```bash
curl -ssL https://raw.githubusercontent.com/portworx/scripts/refs/heads/main/PX_Gather_Logs/x_gather_logs.sh | bash -s -- -n portworx -c kubectl -o PX
```
### Directly upload to FTPS using Curl within script (i.e ftps.purestorage.com) if you have credentials for corresponding case with optional argument "-u" and "-p"
```bash
curl -ssL https://raw.githubusercontent.com/portworx/scripts/refs/heads/main/PX_Gather_Logs/px_gather_logs.sh | bash -s -- -n <namespace> -c <kubectl/oc> -o <PX/PXB> -u <ftpsusername> -p <ftpspassword>
```
---

