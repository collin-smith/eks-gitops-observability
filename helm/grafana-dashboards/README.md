# helm/grafana-dashboards

Ships the demo app's Grafana dashboards as Kubernetes ConfigMaps. Populated
in **Stage 6 (Grafana)**.

Each `*.json` file under `dashboards/` becomes one ConfigMap in the
`monitoring` namespace, labelled `grafana_dashboard: "1"`. The Grafana
dashboard sidecar that ships with `kube-prometheus-stack` (enabled in
`argocd/apps/prometheus.yaml`) watches for that label and loads the
dashboard automatically — no Grafana restart, no manual import through the
UI. The `grafana_folder` annotation files each one under a folder in
Grafana.

Deployed by `argocd/apps/grafana.yaml`.

## Dashboards

- `demo-app-overview.json` — request rate by path, latency quantiles
  (p50/p90/p99), 5xx ratio, status-code breakdown, items-created counter,
  and pod CPU / memory / restarts. All panels query metrics the app
  actually exposes (`http_requests_total`, `http_request_duration_seconds`)
  plus cAdvisor / kube-state-metrics for the pod-level panels.

## Editing a dashboard

Edit it in the Grafana UI, then **Dashboard settings → JSON Model**, copy
that back over the file here, and commit. ArgoCD re-syncs the ConfigMap and
the sidecar reloads it. Keep `"version"` and `"id"` stable so the diff
stays readable.
