# px_metrics_dump_exporter.sh

## Description
Extract the px-metrics from prometheus and export to a file. This script generates the tarball file with the px_metrics_export values and analyse the file for presence of metrics

### Mandatory Parameters
| **Parameter** | **Description**                                                                 | **Example**                          |
|---------------|---------------------------------------------------------------------------------|--------------------------------------|
| `--prom-ns`   | Namespace where Prometheus is running and scrapping px-metrics                  | `--prom-ns portworx` for portworx built=in prometheus, --prom-ns openshift-user-workload-monitoring` for OCP thanos         |
| `--since-days` [OR] `--min-ms <ms> [--max-ms <ms>]`| --since-days --> Use last N days to automatically set min/max time   [OR]    `--min-ms <ms> [--max-ms <ms>]` --> Explicit minimum time (epoch ms), with optional max (defaults to now) | `--since-days 3` [OR]`--min-ms 1730000000000 --max-ms 1730100000000`|


### Optional Parameters
| **Parameter** | **Description**                                                                 | **Example**                          |
|---------------|---------------------------------------------------------------------------------|--------------------------------------|
| `--match-prefix`          | Metric name prefix; expands to --match '{__name__=~"(prefix)_.*"}'. Can be repeated. Defaults to px (i.e., px_*)                                   | `--match-prefix px`                      |
| `--output`          |  Save dump to a local file (default: px_metrics_export_<YYYYMMDD>_<HHMMSS>.om)                                  | `--output px-metrics_prod_cluster.om`                      |
| `--cli`          | CLI to use (default: auto-detect; prefers kubectl, falls back to oc)                                       | `--cli oc`                 |
| `--help`          | how this help message and exit                                               | `--help`                   |



## Usage
Example:
```bash
 px_metrics_dump_exporter.sh --prom-ns portworx --since-days 3
```

#### Where to Execute:
In the host where kubectl or oc CLI is accessible for the cluster.The file gets created on the location where the script is being executed

#### Without Parameters
If no parameters are passed, the script will prompt for input.
````bash
./px_metrics_dump_exporter.sh 
[USER-INPUT-1] Enter Prometheus namespace where PX metrics are exported (e.g., 'portworx' if px-built-in prometheus, 'openshift-user-workload-monitoring' if OCP Thanos-Prometheus): portworx
[USER-INPUT-2] Enter past number of days to export px metrics (e.g., 7): 3
````

#### Execute Using Curl
You can download and execute the script directly from GitHub using the following command:

Example:
```bash
bash <(curl -sSL https://raw.githubusercontent.com/portworx/scripts/refs/heads/sathish-px-metrics-dump-exporter/px_metrics_dump_export/px_metrics_dump_exporter.sh)
```

Sample Execution:
```
$ bash <(curl -sSL https://raw.githubusercontent.com/portworx/scripts/refs/heads/sathish-px-metrics-dump-exporter/px_metrics_dump_export/px_metrics_dump_exporter.sh)
[USER-INPUT-1] Enter Prometheus namespace where PX metrics are exported (e.g., 'portworx' if px-built-in prometheus, 'openshift-user-workload-monitoring' if OCP Thanos-Prometheus): portworx
[USER-INPUT-2] Enter past number of days to export px metrics (e.g., 7): 7
Calculating time range for last 7 day(s)...
Found Prometheus pod: prometheus-px-prometheus-0

=======SUMMARY======
    Using CLI         : kubectl
    Min time          : 1761827199000 (UTC: 2025-10-30T12:26:39.000Z)
    Max time          : 1762431999000 (UTC: 2025-11-06T12:26:39.000Z)
    Getting from pod  : prometheus-px-prometheus-0 (namespace: portworx)
    Saving output to  : px_metrics_export_20251106_122640.om

Extracting PX metrics from prometheus-px-prometheus-0 and saving at /tmp/px_metrics_export_20251106_122640.om
Extraction In-Progress ... ...

Extraction completed. File saved at: /tmp/px_metrics_export_20251106_122640.om


===Validation Summary for presence of metrics on exported file===
  - Total Metrics lines                       : 6387390
  - Total unique Metrics count                : 199
  - Available PX metrics Start time (UTC)     : 2025-11-05T10:00:09.497Z  [epoch_ms: 1762336809497]
  - Available PX metrics End time (UTC)       : 2025-11-06T12:26:24.849Z  [epoch_ms: 1762431984849]

Packaged artifacts into: /tmp/px_metrics_export_20251106_122640.om.tar.gz

Done.
```
---

***Sample Screenshot for executing "px_metrics_dump_exporter.sh"***
<img width="2023" height="630" alt="Screenshot 2025-11-06 at 6 03 11 PM" src="https://github.com/user-attachments/assets/c45c41b1-3a0a-42c1-9903-1845b0ccc269" />


