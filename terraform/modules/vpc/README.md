# terraform/modules/vpc

VPC module: 2 public + 2 private subnets across 2 AZs, an Internet Gateway,
and a NAT gateway (single, shared — `single_nat_gateway = true` by default)
for private-subnet egress. EKS worker nodes run in the private subnets;
the NAT gateway is the only path out. Subnets are tagged for EKS/ELB
auto-discovery (`kubernetes.io/cluster/<name>`, `kubernetes.io/role/elb`,
`kubernetes.io/role/internal-elb`).

Set `single_nat_gateway = false` for one NAT gateway per AZ instead — more
resilient, costs more (~$32+/mo per additional NAT gateway if left running).
Single NAT is the default here since this is a portfolio/demo environment,
not a production HA requirement.
