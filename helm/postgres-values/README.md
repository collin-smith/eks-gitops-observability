# helm/postgres-values

Values overlay for a third-party Postgres chart (Bitnami or similar), rather
than a hand-rolled chart — closer to how real teams run in-cluster Postgres.
Populated in **Stage 3 (Helm)**.

Credentials are plain Kubernetes Secrets for this project — a documented
simplification. Production would use Sealed Secrets, External Secrets, or
SOPS instead.
