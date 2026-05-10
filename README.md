# Terraform Reusable Modules

A collection of production-ready, multi-cloud Terraform modules built for AWS (primary), with architecture designed to extend to Azure and GCP. Built as a portfolio project demonstrating infrastructure-as-code best practices, reusable module design, and multi-environment deployments.

---

## Table of Contents

- [Terraform Reusable Modules](#terraform-reusable-modules)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Project Structure](#project-structure)
  - [Modules](#modules)
    - [Networking](#networking)
    - [Compute](#compute)
    - [Kubernetes](#kubernetes)
    - [Database](#database)
  - [Environments](#environments)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Initialize the project](#initialize-the-project)
    - [Deploy an environment](#deploy-an-environment)
  - [Usage](#usage)
    - [Calling a module directly](#calling-a-module-directly)
  - [Variables Reference](#variables-reference)
    - [Root Variables (`variables.tf`)](#root-variables-variablestf)
  - [Requirements](#requirements)
  - [Contributing](#contributing)

---

## Overview

This project provides a set of reusable Terraform modules that follow a consistent interface pattern. AWS is the primary implementation. Each module is self-contained and designed to be composed together to build full infrastructure stacks across dev, staging, and production environments.

---

## Project Structure

```
terraform-modules/
├── versions.tf                  # Provider versions and Terraform version constraint
├── variables.tf                 # Root-level shared variables (cloud provider, environment, project)
├── README.md
├── .gitignore
├── .terraform-version
│
├── modules/
│   ├── networking/
│   │   └── aws/                 # VPC, subnets, IGW, NAT gateway, route tables
│   │
│   ├── compute/
│   │   └── aws/                 # EC2, Launch Template, Auto Scaling Group
│   │
│   ├── kubernetes/
│   │   └── aws/                 # EKS cluster, managed node groups, OIDC
│   │
│   └── database/
│       └── aws/                 # RDS (MySQL / PostgreSQL), subnet group, parameter group
│
└── environments/
    ├── dev/                     # Development environment
    ├── staging/                 # Staging environment
    └── prod/                    # Production environment
```

---

## Modules

### Networking

Creates a full network layer: VPC, public and private subnets across multiple availability zones, internet gateway, NAT gateway, and route tables.

| Resource | Description |
|----------|-------------|
| VPC | Isolated virtual network |
| Public Subnets | Internet-facing subnets across multiple AZs |
| Private Subnets | Internal subnets for compute and databases |
| Internet Gateway | Outbound internet access for public subnets |
| NAT Gateway | Outbound internet access for private subnets |
| Route Tables | Routing rules for public and private subnets |

> **Status:** Coming soon

---

### Compute

Provisions virtual machines with optional auto-scaling on top of the networking layer.

| Resource | Description |
|----------|-------------|
| Launch Template | Reusable EC2 configuration |
| Auto Scaling Group | Dynamic scaling of EC2 instances |
| Security Group | Inbound/outbound traffic rules |
| IAM Instance Profile | EC2 permissions via IAM role |

> **Status:** Coming soon

---

### Kubernetes

Deploys a managed EKS cluster with configurable node groups.

| Resource | Description |
|----------|-------------|
| EKS Cluster | Managed Kubernetes control plane |
| Managed Node Groups | Worker nodes with auto-scaling |
| IAM Roles | Cluster and node group permissions |
| OIDC Provider | Enables IAM Roles for Service Accounts (IRSA) |

> **Status:** Coming soon

---

### Database

Provisions a managed RDS relational database with subnet group placement inside the private network layer.

| Resource | Description |
|----------|-------------|
| RDS Instance | Managed MySQL or PostgreSQL database |
| DB Subnet Group | Subnet placement for the database |
| Parameter Group | Database engine configuration |
| Security Group | Database access control |

> **Status:** Coming soon

---

## Environments

Each environment folder is a standalone Terraform root module that calls the shared modules above. Environments differ in instance sizes, redundancy settings, and scale.

| Environment | Purpose | Notable Differences |
|-------------|---------|-------------------|
| `dev` | Development and testing | Smallest sizes, single NAT, no multi-AZ |
| `staging` | Pre-production validation | Medium sizes, mirrors prod architecture |
| `prod` | Live production traffic | Largest sizes, multi-AZ, deletion protection on |

---

## Getting Started

### Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.9.0
- AWS CLI configured: `aws configure` or environment variables (`AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`)

### Initialize the project

```bash
terraform init
```

### Deploy an environment

```bash
cd environments/dev
terraform init
terraform plan
terraform apply
```

---

## Usage

### Calling a module directly

```hcl
module "networking" {
  source = "../../modules/networking/aws"

  project_name         = "my-project"
  environment          = "dev"
  vpc_cidr             = "10.0.0.0/16"
  azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  enable_nat_gateway   = true
}
```

---

## Variables Reference

### Root Variables (`variables.tf`)

| Variable                | Type   | Default       | Description                              |
|-------------------------|--------|---------------|------------------------------------------|
| `cloud_provider`        | string | `aws`         | Target cloud: `aws`, `azure`, or `gcp`  |
| `aws_region`            | string | `us-east-1`   | AWS region                               |
| `azure_location`        | string | `East US`     | Azure location                           |
| `azure_subscription_id` | string | `""`          | Azure subscription ID                    |
| `gcp_project`           | string | `""`          | GCP project ID                           |
| `gcp_region`            | string | `us-central1` | GCP region                               |
| `environment`           | string | `dev`         | Deployment environment                   |
| `project_name`          | string | `my-project`  | Used for resource naming and tagging     |

> Each module's variables are documented in the module's own `README.md`.

---

## Requirements

| Tool          | Version  |
|---------------|----------|
| Terraform     | >= 1.9.0 |
| AWS Provider  | ~> 5.0   |

---

## Contributing

1. Create a feature branch: `git checkout -b feature/module-name`
2. Follow the existing module structure (`main.tf`, `variables.tf`, `outputs.tf`)
3. Open a pull request with a description of the module and resources it creates

---

*Built by Haricharantej Tankasala — Infrastructure as Code(Iac)*
