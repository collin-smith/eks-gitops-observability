# argocd/apps

ArgoCD Application manifests. Apply order doesn't matter to ArgoCD, but
roughly: Postgres and demo-app (Stage 4), then Prometheus (Stage 5), then
the Grafana dashboards (Stage 6), then Karpenter (Stage 7).

| Application               | Source                                   | Namespace    | Stage |
|---------------------------|------------------------------------------|--------------|-------|
| `postgres.yaml`           | upstream Bitnami chart + inline values    | `default`    | 4     |
| `demo-app.yaml`           | `helm/demo-app` in this repo              | `default`    | 4     |
| `prometheus.yaml`         | upstream `kube-prometheus-stack`          | `monitoring` | 5     |
| `grafana.yaml`            | `helm/grafana-dashboards` in this repo    | `monitoring` | 6     |
| `karpenter.yaml`          | `public.ecr.aws/karpenter` OCI chart      | `kube-system`| 7     |
| `karpenter-nodepool.yaml` | `karpenter/` in this repo (NodePool + EC2NodeClass) | `kube-system` | 7 |

Grafana itself ships inside `kube-prometheus-stack` — `prometheus.yaml`
enables it and its dashboard sidecar; `grafana.yaml` only adds the custom
dashboards as ConfigMaps.

Karpenter's AWS prerequisites (IRSA role, interruption queue, discovery
tags) come from `terraform/modules/karpenter` — apply that first. The
managed node group stays as baseline capacity; Karpenter adds nodes for
workload bursts within the `NodePool`'s `limits.cpu`.

Should also cover the rollback story (see "Open / deferred" in the top-level
README) — not just drift detection.
