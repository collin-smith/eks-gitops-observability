# Copy to terraform.tfvars and adjust before `terraform apply`.

aws_region = "us-east-1"

# Restrict this to your own IP before applying, e.g. ["203.0.113.4/32"].
# Left wide open by default so the portfolio README's copy-paste steps work
# without editing anything first — tighten this for anything beyond a demo.
public_access_cidrs = ["0.0.0.0/0"]

# EKS stops publishing node-group AMIs for versions that age out of support.
# If `terraform apply` fails on the node group with an AMI error, check what's
# current and override here:
#   aws eks describe-cluster-versions --query "clusterVersions[?versionStatus=='STANDARD_SUPPORT'].clusterVersion"
# cluster_version = "1.34"

# New AWS accounts are sometimes restricted to free-tier-eligible instance
# types only (an anti-fraud guardrail). If `terraform apply` fails on the node
# group with "not eligible for Free Tier", check what's allowed and override:
#   aws ec2 describe-instance-types --filters Name=free-tier-eligible,Values=true --query 'InstanceTypes[]'
# node_instance_types = ["t3.small"]
