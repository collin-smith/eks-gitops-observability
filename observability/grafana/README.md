# observability/grafana

Grafana runs as part of `kube-prometheus-stack` — Stage 5 installed the
stack with Grafana disabled; Stage 6 turns it on in
`argocd/apps/prometheus.yaml` and points its dashboard sidecar at labelled
ConfigMaps.

The dashboard JSON and the chart that packages it into those ConfigMaps
live in **`helm/grafana-dashboards/`**, so the dashboards get the same
`helm lint` CI coverage as every other chart. This directory is kept as the
documented home for "Grafana provisioning" but the source of truth is that
chart.

See `helm/grafana-dashboards/README.md` for how the sidecar discovery works
and how to round-trip a dashboard edited in the UI back into Git.
