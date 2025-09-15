# VK Infrastructure Deployment Guide

## Overview

This repository contains all infrastructure as code for Visual Knowledge services. Any changes to production servers should be made through this repository.

## Architecture

```
Internet -> CloudFront -> API Server (EC2)
                            |
                          Nginx (443)
                            |
                       Flask API (5005)
                            |
                        PostgreSQL RDS
```

## Server Access

```bash
# Direct access via bastion
ssh -J ec2-user@13.52.186.124 ubuntu@172.31.0.108

# Using alias
vk_api
```

## Deployment Methods

### 1. Quick Deploy (Makefile)

```bash
# Deploy everything
make deploy-api-server

# Deploy only monitoring
make deploy-monitoring

# Check status
make status

# View logs
make logs
```

### 2. Manual Deploy (Scripts)

```bash
# Deploy API configuration
./scripts/deploy-api.sh

# Sync from production
./scripts/sync-from-server.sh

# Backup current config
./scripts/backup.sh
```

### 3. Ansible Deploy

```bash
# Setup inventory
echo "[api_server]
172.31.0.108 ansible_user=ubuntu ansible_ssh_common_args='-o ProxyCommand=\"ssh -W %h:%p ec2-user@13.52.186.124\"'" > ansible/inventory/hosts

# Run playbook
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/deploy-api.yml
```

## Configuration Files

### Systemd Service
- Location: `/etc/systemd/system/vk-api.service`
- Config: `api-server/systemd/vk-api.service`
- Features:
  - Auto-restart on failure
  - Memory limit: 1GB
  - Logging to `/var/log/vk-api/`

### Nginx
- Location: `/etc/nginx/sites-available/vk-api`
- Config: `api-server/nginx/vk-api.conf`
- Features:
  - CORS headers for portal
  - SSL termination
  - Proxy to Flask app

### Log Rotation
- Location: `/etc/logrotate.d/vk-api`
- Config: `api-server/logs/logrotate.conf`
- Settings:
  - Daily rotation
  - 7 days retention
  - 100MB max size
  - Compression enabled

## Monitoring

### Health Endpoints
- `/health` - Basic health check
- `/health/detailed` - Detailed metrics
- `/health/metrics` - Datadog format

### Datadog
1. Set API key:
```bash
export DD_API_KEY="your-key"
```

2. Metrics sent:
- vk.api.health.status
- vk.api.memory.rss
- vk.api.cpu.percent
- vk.api.connections.count
- vk.nginx.status
- vk.disk.usage.percent

### CloudWatch
Namespace: `VK/API`

Metrics:
- APIHealth
- MemoryUsage
- CPUUtilization
- ConnectionCount
- NginxHealth
- DiskUsagePercent

### Alerts

CloudWatch Alarms:
- VK-API-Health-Check (API down)
- VK-API-High-Memory (> 800MB)
- VK-API-High-CPU (> 80%)

## Emergency Procedures

### API Down
```bash
# Quick restart
make restart-api

# Manual restart
ssh -J ec2-user@13.52.186.124 ubuntu@172.31.0.108
sudo systemctl restart vk-api
sudo systemctl status vk-api
```

### High Memory
```bash
# Check memory usage
ssh -J ec2-user@13.52.186.124 ubuntu@172.31.0.108
ps aux | grep python
free -h

# Restart if needed
sudo systemctl restart vk-api
```

### Disk Full
```bash
# Check disk usage
df -h
du -sh /var/log/vk-api/

# Force log rotation
sudo logrotate -f /etc/logrotate.d/vk-api

# Clean old logs
sudo find /var/log/vk-api/ -name "*.gz" -mtime +7 -delete
```

### Rollback
```bash
# Rollback to previous version
make rollback

# Manual rollback
git checkout HEAD~1
make deploy-api-server
```

## Development Workflow

1. Make changes in this repository
2. Test locally if possible
3. Create pull request
4. After review, merge to main
5. Deploy to production:
   ```bash
   git pull origin main
   make deploy-api-server
   ```

## Adding New Configuration

1. Add configuration file to appropriate directory
2. Update deployment script or Ansible playbook
3. Test deployment
4. Commit and push:
   ```bash
   git add .
   git commit -m "Add new configuration for X"
   git push origin main
   ```

## Security Notes

- Never commit secrets or API keys
- Use environment variables for sensitive data
- Store keys in AWS Secrets Manager or Parameter Store
- Review all changes before deploying to production

## Troubleshooting

### Service won't start
```bash
# Check logs
sudo journalctl -u vk-api -n 100
tail -f /var/log/vk-api/error.log

# Check port
sudo lsof -i :5005
```

### CORS errors
- Check nginx config has correct origin
- Verify OPTIONS handling
- Check Flask CORS configuration

### 502 Bad Gateway
- API service is down
- Check if Flask is running
- Check nginx can reach port 5005

## Support

For issues, contact the VK DevOps team or create an issue in this repository.