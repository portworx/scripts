# px_gmetrics_dump_exporter.sh

## Description
Extract the px-metrics from prometheus and export to a file. This script generates the tarball file with the px_metrics_export values and analyse the file for presence of metrics

### Mandatory Parameters
| **Parameter** | **Description**                                                                 | **Example**                          |
|---------------|---------------------------------------------------------------------------------|--------------------------------------|
| `--prom-ns`   | Namespace where Prometheus is running and scrapping px-metrics                  | `--prom-ns portworx` for portworx built=in prometheus, --prom-ns openshift-user-workload-monitoring` for OCP thanos         |
| `--since-days` [OR] `--min-ms <ms> [--max-ms <ms>]`| --since-days -> Use last N days to automatically set min/max time [OR] --min-ms <ms> [--max-ms <ms>] Explicit minimum time (epoch ms), with optional max (defaults to now) | `--since-days 3` [OR]--min-ms 1730000000000 --max-ms 1730100000000|


### Optional Parameters
| **Parameter** | **Description**                                                                 | **Example**                          |
|---------------|---------------------------------------------------------------------------------|--------------------------------------|
| `--match-prefix`          | Metric name prefix; expands to --match '{__name__=~"(prefix)_.*"}'. Can be repeated. Defaults to px (i.e., px_*)                                   | `--match-prefix px`                      |
| `--output`          |  Save dump to a local file (default: px_metrics_export_<YYYYMMDD>_<HHMMSS>.om)                                  | `---output px-metrics_prod_cluster.om`                      |
| `--cli`          | CLI to use (default: auto-detect; prefers kubectl, falls back to oc)                                       | `--cli oc`                 |
| `--help`          | how this help message and exit                                               | `--help`                   |



## Usage
Example:
```bash
 px_metrics_dump_exporter.sh --prom-ns portworx --since-days 3 --match-prefix px
```

### Without Parameters
If no parameters are passed, the script will prompt for input.
````bash
./px_metrics_dump_exporter.sh 
Enter Prometheus namespace where PX metrics are exported (e.g., 'portworx' if px-built-in prometheus, 'openshift-user-workload-monitoring' if OCP Thanos-Prometheus): portworx
Enter past number of days to export px metrics (e.g., 7): 3
````

### Execute Using Curl
You can download and execute the script directly from GitHub using the following command:
Example:
```bash
bash <(curl -sSL https://raw.githubusercontent.com/portworx/scripts/refs/heads/sathish-px-metrics-dump-exporter/px_metrics_dump_export/px_metrics_dump_exporter.sh)
```

Sample Execution:
```
root@ip-10-13-169-97:~# bash <(curl -sSL https://raw.githubusercontent.com/portworx/scripts/refs/heads/sathish-px-metrics-dump-exporter/px_metrics_dump_export/px_metrics_dump_exporter.sh)
Enter Prometheus namespace where PX metrics are exported (e.g., 'portworx' if px-built-in prometheus, 'openshift-user-workload-monitoring' if OCP Thanos-Prometheus): portworx
Enter past number of days to export px metrics (e.g., 7): 7
Calculating time range for last 7 day(s)...
Found Prometheus pod: prometheus-px-prometheus-0

=======SUMMARY======
    Using CLI         : kubectl
    Min time          : 1761797571000 (UTC: 2025-10-30T04:12:51.000Z)
    Max time          : 1762402371000 (UTC: 2025-11-06T04:12:51.000Z)
    Getting from pod  : prometheus-px-prometheus-0 (namespace: portworx)
    Saving output to  : px_metrics_export_20251106_041251.om

Extracting PX metrics from prometheus-px-prometheus-0 and saving at /root/px_metrics_export_20251106_041251.om
Extraction In-Progress ... ...

Extraction completed. File saved at: /root/px_metrics_export_20251106_041251.om


===Validation Summary for presence of metrics on exported file===
  - Total Metrics lines                       : 6775241
  - Total unique Metrics count                : 198
  - Available PX metrics Start time (UTC)     : 2025-11-05T02:00:09.497Z  [epoch_ms: 1762308009497]
  - Available PX metrics End time (UTC)       : 2025-11-06T04:12:49.433Z  [epoch_ms: 1762402369433]

Packaged artifacts into: /root/px_metrics_export_20251106_041251.om.tar.gz

Done.
```
---

***Sample Screenshot for executing "px_metrics_dump_exporter.sh"***
<img width="1339" height="587" alt="Screenshot 2025-11-04 at 3 45 20 PM" src="https://github.com/user-attachments/assets/60b92bda-d285-477c-971b-0befb0e7f41f" />
