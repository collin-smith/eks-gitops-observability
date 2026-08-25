# terraform/envs/dev

Root Terraform config for the dev environment — wires up the `vpc`, `eks`,
and `ecr` modules. Local state (no remote backend configured yet).

```
cp terraform.tfvars.example terraform.tfvars   # restrict public_access_cidrs to your IP
terraform init
terraform plan
terraform apply
```

`terraform output configure_kubectl` prints the `aws eks update-kubeconfig`
command to point `kubectl` at the new cluster once it's up.
