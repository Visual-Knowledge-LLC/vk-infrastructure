# VK Infrastructure as Code

This repository contains all infrastructure configuration for Visual Knowledge services.

## Repository Structure

```
vk-infrastructure/
├── api-server/              # API server configurations
│   ├── systemd/            # System service definitions
│   ├── nginx/              # Nginx configurations
│   ├── monitoring/         # Monitoring scripts
│   ├── logs/               # Log rotation configs
│   └── scripts/            # Deployment scripts
├── terraform/              # Terraform IaC definitions
│   ├── ec2/               # EC2 instance configs
│   ├── rds/               # Database configs
│   └── networking/        # VPC, security groups
├── ansible/               # Configuration management
│   ├── playbooks/         # Deployment playbooks
│   └── roles/             # Ansible roles
├── docker/                # Docker configurations
├── kubernetes/            # K8s manifests (future)
└── docs/                  # Documentation
```

## Quick Start

### Deploy API Server Configuration
```bash
make deploy-api-server
```

### Update Monitoring
```bash
make update-monitoring
```

### Backup Current Configuration
```bash
make backup-config
```

## Server Inventory

| Server | IP | Purpose | Environment |
|--------|-----|---------|-------------|
| api_server_restored | 54.177.224.206 | API Server | Production |
| Bastion | 13.52.186.124 | Jump Host | Production |

## Key Management

- SSH keys are stored in AWS Secrets Manager
- API keys are in environment variables
- Datadog keys: Set DD_API_KEY environment variable

## Deployment Process

1. Make changes in this repository
2. Test locally: `make test`
3. Deploy to staging: `make deploy-staging`
4. Deploy to production: `make deploy-prod`

## Monitoring

- Datadog: https://app.datadoghq.com
- CloudWatch: VK/API namespace
- Logs: /var/log/vk-api/

## Emergency Procedures

### Restart API
```bash
make restart-api
```

### Rollback Deployment
```bash
make rollback
```

### View Logs
```bash
make logs
```