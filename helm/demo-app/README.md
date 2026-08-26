# helm/demo-app

Helm chart for the demo app. Populated in **Stage 3 (Helm)**.

## Install

```
helm install demo helm/demo-app \
  --set image.repository=$(terraform -chdir=terraform/envs/dev output -raw ecr_repository_url) \
  --set image.tag=<git-sha-or-tag> \
  --set database.url="postgresql://demo:<password>@pg-postgresql:5432/demo"
```

`database.url` must match the Bitnami Postgres release from
`helm/postgres-values` (see that chart's README for the install command and
the exact hostname it lands on).

