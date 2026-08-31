# AWS Infrastructure Automation & Monitoring using Terraform

Secure, automated AWS infrastructure provisioned entirely with Terraform (IaC), including networking, compute, storage, IAM, backup, and cost-monitoring , deployed via a CI/CD pipeline built on GitHub Actions using OIDC-based (keyless) authentication.

## What this project does

Instead of manually clicking through the AWS Console to set things up, everything here is written as code using Terraform. Run one command, and it automatically builds the entire environment below.

- **Networking** — Creates a private network in AWS (a VPC) with a public section where the server lives, plus a gateway so it can reach the internet.
- **Server** — Launches an EC2 server and automatically installs a web server on it at startup, so a webpage is live as soon as it boots.
- **Storage** — Creates an S3 bucket (AWS file storage) with versioning turned on, so old file versions aren't lost if something gets overwritten.
- **Security** — Locks things down: remote login (SSH) only works from one trusted IP address, not the whole internet. Every part of the system only gets the exact permissions it needs, not full admin access.
- **Backup & monitoring** — Automatically backs up the server on a schedule, and sends an email alert if AWS spending goes above a set limit.
- **Automated deployment** — Connected to GitHub Actions, so every code push automatically checks and deploys the infrastructure. Instead of storing AWS passwords in GitHub, it uses a more secure method (OIDC) where GitHub and AWS trust each other directly — no stored keys at all.

## Architecture

```
                          ┌─────────────────────────────┐
                          │      GitHub Actions CI/CD   │
                          │(OIDC → AssumeRoleWithWebId) │
                          └───────────────┬─────────────┘
                                          │ terraform plan / apply
                                          ▼
┌───────────────────────────── AWS Account ─────────────────────────────┐
│                                                                       │
│   ┌───────────────── VPC (10.0.0.0/16) ───────────────────┐           │
│   │                                                       │           │
│   │   ┌────────── Public Subnet ──────────┐               │           │
│   │   │                                   │               │           │
│   │   │   EC2 (Amazon Linux 2023)         │◄── Internet   │           │
│   │   │   - Apache web server             │    Gateway    │           │
│   │   │   - Security Group (80 open,      │               │           │
│   │   │     22 restricted to my IP)       │               │           │
│   │   └───────────────────────────────────┘               │           │
│   │              Route Table → 0.0.0.0/0 via IGW          │           │
│   └───────────────────────────────────────────────────────┘           │
│                                                                       │
│   S3 Bucket (versioned + lifecycle rule)                              │
│   IAM Role (Backup role - least privilege)                            │
│   AWS Backup Vault + Plan (daily EC2 backups)                         │
│   CloudWatch Billing Alarm → SNS → Email                              │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

## Repository structure

```
aws-terraform-infrastructure/
├── .github/workflows/       # GitHub Actions CI/CD pipeline (Terraform plan/apply)
├── main.tf                  # VPC, subnet, IGW, route table, security group, EC2, S3
├── iam.tf                   # IAM role/policy (AWS Backup service role)
├── backup.tf                # AWS Backup vault, plan, and selection
├── cloudwatch.tf            # CloudWatch billing alarm + SNS topic/subscription
├── variables.tf             # Input variables
├── outputs.tf               # Output values (EC2 IP, bucket name, etc.)
├── provider.tf              # AWS provider configuration
├── versions.tf              # Terraform/provider version constraints
├── userdata.sh              # EC2 bootstrap script (installs & starts Apache)
└── .gitignore               # Excludes state files, .tfvars, and secrets
```

## Prerequisites

- An AWS account with a least-privilege IAM user for Terraform (not the root user)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5
- [AWS CLI](https://aws.amazon.com/cli/), configured (`aws configure`)
- An existing EC2 key pair in your target region (for SSH access)
- Git

## Setup

1. Clone the repo:
   ```bash
   git clone https://github.com/wandkarbhoomika/aws-terraform-infrastructure.git
   cd aws-terraform-infrastructure
   ```

2. Create a `terraform.tfvars` file (this is gitignored and never committed):
   ```hcl
   aws_region         = "ap-south-1"
   project_name       = "terraform-infrastructure"
   environment        = "dev"
   vpc_cidr           = "10.0.0.0/16"
   public_subnet_cidr = "10.0.1.0/24"
   instance_type      = "t2.micro"
   allowed_ssh_cidr   = "YOUR_IP/32"
   key_name           = "your-ec2-key-pair-name"
   ```

3. Initialize and deploy:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. Validate the deployment:
   ```bash
   terraform output ec2_public_ip
   curl http://<ec2_public_ip>
   ```

5. Tear down when you're done (to avoid ongoing charges):
   ```bash
   terraform destroy
   ```

## CI/CD Pipeline

Every push or pull request to `main` triggers `.github/workflows/`:

| Event | What runs |
|---|---|
| Pull request to `main` | `terraform fmt -check`, `terraform validate`, `terraform plan` |
| Push (merge) to `main` | All of the above, plus `terraform apply -auto-approve` |

Authentication uses an **OIDC identity provider** (`token.actions.githubusercontent.com`) and an IAM role scoped to this exact repository and branch — GitHub Actions never has a static AWS access key.

## Security & cost design choices

- **No root or admin credentials used by automation** — a dedicated least-privilege IAM user/role provisions all infrastructure.
- **SSH restricted to a single IP** via the security group, instead of open to everyone.
- **S3 versioning + lifecycle rules** protect against accidental overwrites/deletions while automatically cleaning up old versions to control storage cost.
- **AWS Backup** provides scheduled, automated backups of the EC2 instance.
- **CloudWatch billing alarm + SNS** gives an early warning if AWS spend exceeds an expected threshold.

## Notes

This is a portfolio/learning project built to demonstrate Infrastructure-as-Code, AWS networking fundamentals, least-privilege IAM design, and CI/CD automation. It intentionally uses a single public subnet (no NAT Gateway/private tier) to keep the AWS Free Tier footprint small.
