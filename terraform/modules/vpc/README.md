# terraform/modules/vpc

VPC module: subnets, routing, gateways. Populated in **Stage 2 (EKS)**.

NAT/private-subnet design is deferred — see the "Open / deferred" section of
the top-level README. Initial version may use public subnets for simplicity;
revisit before the EKS article is written up.
