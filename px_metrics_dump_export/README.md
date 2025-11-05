1) Generate Prometheus TSDB dump from Prometheus [To be done at Prometheus]

- Execute into Prometheus Pod
- Generate Prometheus TSDB dump using below promtool command

```
promtool tsdb dump-openmetrics \
            --min-time=$MIN_MS \
            --max-time=$MAX_MS \
            --match '{__name__=~"px_.*"}'
            '/prometheus'
```
Where $MIN_MS and $MAX_MS are optional parameter to configure the export window

***Scripted Approach for exporting px-metrics from customer cluster:***

A script "px_metrics_dump_exporter.sh" is created for this which gets below two arguments
- Prometheus namespace where PX metrics are exported (e.g., 'portworx' if px-built-in prometheus, 'openshift-user-workload-monitoring' if OCP Thanos-Prometheus)
- Past number of days to export px metrics (e.g., 7)

which exports the px-metrics dump to “export_yyyymmdd_hhmmss.om”

Once exported, this script validates the exported metrics for 
  - Total Metrics lines                       : 
  - Total unique Metrics count                : 
  - Available PX metrics Start time (UTC)     : 
  - Available PX metrics End time (UTC)       : 

And compress this exported dump along with its log file at “px_metrics_export_yyyymmdd_<hhmmss.tar.gz”

***Sample Screenshot for executing "ppx_metrics_dump_exporter.sh"***
<img width="1339" height="587" alt="Screenshot 2025-11-04 at 3 45 20 PM" src="https://github.com/user-attachments/assets/612d42d1-d3bd-4597-b637-6684245d86c6" />
