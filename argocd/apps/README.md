# argocd/apps

ArgoCD Application manifests. Apply order doesn't matter to ArgoCD, but
roughly: Postgres and demo-app (Stage 4), then Prometheus (Stage 5), then
the Grafana dashboards (Stage 6).

| Application            | Source                                   | Namespace  | Stage |
|------------------------|------------------------------------------|------------|-------|
| `postgres.yaml`        | upstream Bitnami chart + inline values    | `default`  | 4     |
| `demo-app.yaml`        | `helm/demo-app` in this repo              | `default`  | 4     |
| `prometheus.yaml`      | upstream `kube-prometheus-stack`          | `monitoring` | 5   |
| `grafana.yaml`         | `helm/grafana-dashboards` in this repo    | `monitoring` | 6   |

Grafana itself ships inside `kube-prometheus-stack` — `prometheus.yaml`
enables it and its dashboard sidecar; `grafana.yaml` only adds the custom
dashboards as ConfigMaps.

Should also cover the rollback story (see "Open / deferred" in the top-level
README) — not just drift detection.
