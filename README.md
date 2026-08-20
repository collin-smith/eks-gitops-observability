# EKS GitOps Observability

A portfolio project demonstrating a production-shaped deployment pipeline:

**Docker → EKS (Terraform) → Helm → ArgoCD (GitOps) → Prometheus → Grafana**

Built to close specific hands-on gaps (Docker, Helm, ArgoCD, Prometheus, Grafana)
against existing CKAD certification and deep Terraform/EKS experience — in the
order those gaps actually appear in a real deployment pipeline.

## Stages

Each stage is a working, demoable milestone with its own article and diagram.
Articles and diagrams live outside this repo, in the workspace-level
`outputs/` folder (see "Workspace layout" below) — this repo holds code only.

| # | Stage      | Article                     | Diagram                       |
|---|------------|-------------------------------|----------------------------------|
| 1 | Docker     | `01-docker.md`                | `01-docker.drawio`               |
| 2 | EKS        | `02-eks.md`                   | `02-eks.drawio`                  |
| 3 | Helm       | `03-helm.md`                  | `03-helm.drawio`                 |
| 4 | ArgoCD     | `04-argocd.md`                | `04-argocd.drawio`               |
| 5 | Prometheus | `05-prometheus.md`            | `05-prometheus.drawio`           |
| 6 | Grafana    | `06-grafana.md`               | `06-grafana.drawio`              |

Paths are relative to `outputs/eks-gitops-observability/articles/`. Articles
publish to collin-smith.medium.com. Diagrams are cumulative — each stage's
diagram builds on the previous stage's architecture.

## Workspace layout

This repo lives under a workspace root with three top-level folders:

```
kubernetes/
├── inputs/                          Source material feeding this and other projects
├── outputs/eks-gitops-observability/  Articles, diagrams — deliverables, not code
└── code/eks-gitops-observability/     This repo
```

## Layout

```
terraform/modules/{vpc,eks,ecr}/   Terraform modules
terraform/envs/dev/                Terraform environment (dev)
app/                                Demo app (Python/FastAPI): /health, /metrics, /docs
helm/demo-app/                     Helm chart for the demo app
helm/postgres-values/              Values overlay for a third-party Postgres chart
argocd/apps/                       ArgoCD Application manifests
observability/prometheus/          ServiceMonitor + alert rules
observability/grafana/             Dashboards (JSON) + provisioning
```

## Decisions

These were settled up front so later stages aren't guessing at layout or scope:

- **Postgres**: a third-party chart (Bitnami or similar) as a dependency, with
  a values overlay in `helm/postgres-values/` — rather than a hand-rolled
  chart. Closer to how real teams run in-cluster Postgres, less code to
  maintain.
- **Secrets**: plain Kubernetes Secrets, explicitly documented as a known
  simplification. Production would use Sealed Secrets, External Secrets, or
  SOPS — noted in the relevant article rather than implemented, to keep scope
  tight.
- **CI**: a minimal GitHub Actions workflow (`.github/workflows/ci.yml`)
  scaffolded from day one — app build/test, `terraform validate`/`fmt`, `helm
  lint` — rather than bolted on later. Each job only runs once its target
  directory has content, so the workflow is a no-op until each stage lands.

## Open / deferred

Flagged for later stages, not blocking now:

- **Rollback/failure story**: stage 4 (ArgoCD) covers drift detection, but
  "what happens when a bad deploy needs to be rolled back" still needs an
  explicit demo and write-up — a common interview question for GitOps roles.
- **Teardown/rebuild automation**: `make up` / `make down` to script the full
  stack lifecycle. Worth timing once it exists ("full stack from git in N
  minutes") as article material.
- **NAT/private-subnet redesign**: current VPC design is deferred until the
  architecture needs to look production-shaped for the writeup.
