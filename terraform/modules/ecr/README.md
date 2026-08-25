# terraform/modules/ecr

ECR repository for the demo app image (`image_tag_mutability = "MUTABLE"`,
scan-on-push enabled, lifecycle policy expiring untagged images after 14
days), referenced by the Helm chart from **Stage 3** onward. The Stage 1
`docker push` deferred until this module existed — now it does.
