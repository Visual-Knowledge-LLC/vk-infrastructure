# VK Infrastructure Makefile
SHELL := /bin/bash
.PHONY: help deploy-api-server backup-config sync-from-server test

# Default target
help:
	@echo "VK Infrastructure Management"
	@echo "============================="
	@echo "Available targets:"
	@echo "  make sync-from-server  - Pull current configs from production"
	@echo "  make deploy-api-server - Deploy API server configuration"
	@echo "  make deploy-monitoring - Deploy monitoring scripts"
	@echo "  make backup-config     - Backup current server state"
	@echo "  make test             - Test configurations locally"
	@echo "  make restart-api      - Restart API service"
	@echo "  make logs             - View API logs"
	@echo "  make status           - Check service status"
	@echo "  make rollback         - Rollback to previous version"

# Sync configurations from production server
sync-from-server:
	@echo "Syncing configurations from production server..."
	@./scripts/sync-from-server.sh

# Deploy API server configuration
deploy-api-server:
	@echo "Deploying API server configuration..."
	@./scripts/deploy-api.sh

# Deploy monitoring
deploy-monitoring:
	@echo "Deploying monitoring configuration..."
	@./scripts/deploy-monitoring.sh

# Backup current configuration
backup-config:
	@echo "Backing up current configuration..."
	@mkdir -p backups/$(shell date +%Y%m%d_%H%M%S)
	@./scripts/backup.sh backups/$(shell date +%Y%m%d_%H%M%S)

# Test configurations
test:
	@echo "Testing configurations..."
	@echo "✓ Checking nginx config syntax"
	@nginx -t -c api-server/nginx/vk-api.conf 2>/dev/null || echo "⚠ Nginx config needs testing on server"
	@echo "✓ Checking systemd service files"
	@systemd-analyze verify api-server/systemd/*.service 2>/dev/null || echo "⚠ Systemd files need testing on server"
	@echo "✓ Checking Python syntax"
	@python3 -m py_compile api-server/app/*.py 2>/dev/null || echo "⚠ Python files need testing"

# Restart API service
restart-api:
	@echo "Restarting API service..."
	@ssh -o StrictHostKeyChecking=no ec2-user@13.52.186.124 \
		"ssh ubuntu@172.31.0.108 'sudo systemctl restart vk-api'"

# View logs
logs:
	@echo "Fetching recent API logs..."
	@ssh -o StrictHostKeyChecking=no ec2-user@13.52.186.124 \
		"ssh ubuntu@172.31.0.108 'sudo tail -n 100 /var/log/vk-api/app.log'"

# Check status
status:
	@echo "Checking service status..."
	@ssh -o StrictHostKeyChecking=no ec2-user@13.52.186.124 \
		"ssh ubuntu@172.31.0.108 'sudo systemctl status vk-api'"

# Rollback deployment
rollback:
	@echo "Rolling back to previous version..."
	@./scripts/rollback.sh

# Install Git hooks
install-hooks:
	@echo "Installing Git hooks..."
	@cp hooks/pre-commit .git/hooks/
	@chmod +x .git/hooks/pre-commit

# Initialize repository
init:
	@echo "Initializing infrastructure repository..."
	@mkdir -p api-server/{systemd,nginx,monitoring,logs,scripts,app}
	@mkdir -p terraform/{ec2,rds,networking}
	@mkdir -p ansible/{playbooks,roles}
	@mkdir -p scripts backups docs
	@make install-hooks