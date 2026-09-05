# terraform-infrastructure

AWS infrastructure for the ShopStream platform: VPC, EKS cluster, ECR
repositories, a shared RDS Postgres instance (four per-service databases),
and a DocumentDB cluster (MongoDB-compatible, for notification-service).

## Structure

```text
terraform-infrastructure/
├── bootstrap/              Terraform's own remote-state backend
│                           (S3 bucket + DynamoDB lock table) - apply
│                           this exactly once, before anything else.
├── modules/
│   ├── vpc/                Public + private subnets across 2 AZs, NAT
│   ├── eks/                Cluster, managed node group, OIDC provider
│   ├── rds/                Shared Postgres instance (schema/user
│   │                       creation lives in environments/dev, not here)
│   ├── docdb/               DocumentDB cluster for notification-service
│   └── ecr/                One repository per service (7 total)
└── environments/
    └── dev/                Composes the modules above into one
                            environment. A second environments/prod/
                            would reuse the same modules with different
                            variable values, not duplicate the modules.
```

## Order of operations

**1. Bootstrap the state backend (once, ever):**

```bash
cd bootstrap
terraform init
terraform apply -var="bucket_name=<globally-unique-name>" -var="table_name=shopstream-tf-locks"
terraform output   # note bucket_name and table_name for the next step
```

**2. Point environments/dev at that backend:**

```bash
cd ../environments/dev
cp backend.hcl.example backend.hcl   # fill in the bucket/table from step 1
terraform init -backend-config=backend.hcl
```

**3. Plan, then apply:**

```bash
terraform plan
terraform apply
```

This provisions the VPC, EKS cluster + node group, all 7 ECR repos, the
RDS instance with its 4 service databases/roles, and the DocumentDB
cluster — in one apply. Expect this to take 15-20 minutes; EKS cluster
creation alone is typically 10+ minutes.

**4. Connect kubectl:**

```bash
terraform output configure_kubectl   # prints the exact aws eks command
```

## What this does NOT include, on purpose

- **Kubernetes-level resources** (namespaces, the actual application
  Deployments/Services — those live in the `GitOps` repo) or **Helm/Argo
  CD installation onto the cluster** — this repo's job ends at "a working
  EKS cluster exists," not "the cluster is running the application."
- **A bastion host or CI runner inside the VPC.** See the warning below.
- **Actually wiring the Secrets Manager secrets this creates into
  Kubernetes Secrets.** That's a real, currently-unsolved gap in the
  `GitOps` repo (every `deployment.yaml` already references Secrets that
  don't exist) — the natural fix is installing **External Secrets
  Operator** on the cluster and pointing it at the ARNs in this repo's
  `service_db_secret_arns` / `notification_service_mongo_secret_arn`
  outputs, but installing and configuring ESO itself is not part of this
  repo.

## A real operational wrinkle, not glossed over

The RDS instance is deliberately **not** publicly accessible (see
`modules/rds`) — it only accepts connections from inside the VPC. But
creating the four per-service databases and roles (`environments/dev/
databases.tf`) uses the `postgresql` Terraform provider, which needs to
actually *connect* to that instance during `apply`. If you run `terraform
apply` from your laptop or a Jenkins agent outside the VPC, that specific
part of the apply will hang or fail to connect — everything else (VPC,
EKS, ECR, the RDS/DocumentDB instances themselves) will still succeed.

Two real options, neither automated here:
1. Run `apply` from something already inside the VPC (a bastion host, a
   Cloud9 environment in the VPC, or — once the cluster exists — a
   Jenkins agent running as a pod inside EKS).
2. Temporarily flip `modules/rds`'s security group / `publicly_accessible`
   to allow your specific IP, apply, then revert. Workable for a one-time
   initial setup; not something to leave on.

This repo doesn't include a bastion module. Worth adding one if you want
option 1 to be push-button instead of manual.

## Cost awareness

Nothing in this repo is free-tier. Running `apply` and leaving it up
costs real money continuously — approximately, per month, at the
defaults in `environments/dev`:

| Resource | Rough monthly cost |
|---|---|
| EKS control plane | ~$73 (flat $0.10/hr) |
| 2x t3.medium on-demand nodes | ~$60 |
| RDS db.t3.micro (single-AZ) | ~$13 |
| DocumentDB db.t3.medium x1 | ~$170 (DocumentDB has no small/burstable tier — this is its single biggest line item) |
| NAT Gateway (single, shared) | ~$33 + data processing |
| **Total** | **~$350/month**, before data transfer/storage |

`terraform destroy` tears all of it down when you're not actively using
it — worth doing between practice sessions rather than leaving a cluster
running idle. `var.node_capacity_type = "SPOT"` and turning DocumentDB's
`instance_count` down don't change the DocumentDB tier issue, but they do
meaningfully cut the EKS node cost.

## Known simplifications, stated rather than hidden

- **Postgres's `PUBLIC` role retains default `CONNECT` privilege on every
  database** on the shared RDS instance — see the comment in
  `environments/dev/databases.tf`. No application code is ever given
  another service's database name/credentials, so this isn't reachable
  through the app, but it's not the same as a hard database-level
  guarantee. Revoking `CONNECT FROM PUBLIC` per database is the stricter
  version, deliberately left undone here.
- **EKS API server's public endpoint is open to `0.0.0.0/0`** rather than
  restricted to specific CIDRs — practical for a cluster reached from a
  laptop with a changing IP, not what a real production cluster would do.
- **`deletion_protection = false` and `skip_final_snapshot = true`** on
  both databases, specifically so a portfolio/practice environment can be
  torn down with a plain `terraform destroy` — flip both before this ever
  holds data you can't afford to lose.
