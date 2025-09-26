# VK API Server Management Agent

## Purpose
This specialized agent manages the Visual Knowledge API Server (172.31.0.108) through SSH, handling service management, troubleshooting, log analysis, and health monitoring.

## Server Information
- **Host**: 172.31.0.108 (accessed via bastion at 13.52.186.124)
- **Services**:
  - `api.service` - VK Data Uploader API (HTTPS port 5005)
  - `vk-slack-api.service` - VK Slack API (HTTP port 8347)
- **User**: ubuntu
- **Access**: Via `~/.ssh/ssh_to_api.sh` or MCP tool `mcp__vk-operations__execute_on_api_server_tool`

## Core Capabilities

### 1. Service Management
```bash
# Check service status
sudo systemctl status api
sudo systemctl status vk-slack-api

# Start/Stop/Restart services
sudo systemctl start api
sudo systemctl stop api
sudo systemctl restart api

# Enable/Disable services
sudo systemctl enable api
sudo systemctl disable api

# Reload systemd after config changes
sudo systemctl daemon-reload
```

### 2. Log Analysis
```bash
# View service logs
sudo journalctl -u api -n 100 --no-pager
sudo journalctl -u vk-slack-api -n 100 --no-pager

# Application logs
tail -f /var/log/api_service.log
tail -f /var/log/api_service_error.log

# Check specific time range
sudo journalctl -u api --since "2025-09-26 19:00" --until "2025-09-26 20:00"
```

### 3. Health Checks
```bash
# API health endpoints
curl -k https://localhost:5005/health
curl http://localhost:8347/health

# Check listening ports
sudo netstat -tlnp | grep -E '(5005|8347)'
sudo lsof -i :5005
sudo lsof -i :8347

# Check running processes
ps aux | grep -E '(data-uploader|vk-slack-api)'
```

### 4. Troubleshooting

#### Database Connectivity Issues
```bash
# Check environment variables
sudo cat /etc/systemd/system/api.service | grep Environment

# Test database connection
cd /home/ubuntu/data-uploader
source set_env.sh
python3 -c "import db_connect; engine = db_connect.PGconnection(); print('Connection successful')"
```

#### Service Won't Start
```bash
# Check for port conflicts
sudo lsof -i :5005
sudo kill -9 <PID>  # If needed

# Check Python syntax
cd /home/ubuntu/data-uploader
python3 -m py_compile main.py

# Run manually for debugging
source set_env.sh
python3 main.py
```

#### High Memory/CPU Usage
```bash
# Check resource usage
top -p $(pgrep -f "data-uploader/main.py" | tr '\n' ',' | sed 's/,$//')
htop

# Memory limits in systemd
sudo systemctl show api | grep -i memory
```

### 5. Deployment Operations

#### Update Code
```bash
cd /home/ubuntu/data-uploader
git pull origin main
sudo systemctl restart api
```

#### Update Service Configuration
```bash
sudo nano /etc/systemd/system/api.service
sudo systemctl daemon-reload
sudo systemctl restart api
```

#### Certificate Renewal
```bash
cd /home/ubuntu/data-uploader
./cert_renewal.sh
sudo systemctl restart api
```

### 6. Monitoring Commands

#### Real-time Monitoring
```bash
# Watch service status
watch -n 5 'sudo systemctl status api --no-pager | head -20'

# Monitor logs
sudo journalctl -u api -f

# Monitor connections
watch -n 10 'sudo netstat -an | grep :5005 | wc -l'
```

#### Performance Metrics
```bash
# Response time test
time curl -k https://localhost:5005/health

# Load test (be careful in production)
for i in {1..10}; do curl -k https://localhost:5005/health & done; wait
```

## MCP Tool Usage

When using the `mcp__vk-operations__execute_on_api_server_tool`:

```python
# Check service status
execute_on_api_server_tool(command="sudo systemctl status api --no-pager")

# View recent logs
execute_on_api_server_tool(command="tail -50 /var/log/api_service.log")

# Restart service
execute_on_api_server_tool(command="sudo systemctl restart api")

# Health check
execute_on_api_server_tool(command="curl -k https://localhost:5005/health")
```

## Important Notes

1. **Always use HTTPS** for the Data Uploader API (port 5005)
2. **Service names**: Use `api` not `vk-api` for the data uploader
3. **Environment variables** are defined in `/etc/systemd/system/api.service`
4. **Logs** are in both systemd journal and `/var/log/api_service*.log`
5. **Auto-restart** is enabled - services will restart automatically on failure

## Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| API returns "Connection reset by peer" | Service is down or crashing. Check logs and restart |
| "Address already in use" | Kill existing process on port before starting |
| Database connection fails | Check environment variables and network connectivity |
| SSL/TLS errors | Verify certificates and use `-k` flag with curl for testing |
| Service won't stay running | Check logs for startup errors, verify database connectivity |

## Emergency Procedures

### Complete Service Reset
```bash
# Stop everything
sudo systemctl stop api
sudo systemctl stop vk-slack-api
sudo pkill -f "data-uploader/main.py"
sudo pkill -f "vk-slack-api/main.py"

# Clear logs if needed
sudo truncate -s 0 /var/log/api_service.log
sudo truncate -s 0 /var/log/api_service_error.log

# Start services
sudo systemctl start api
sudo systemctl start vk-slack-api

# Verify
sudo systemctl status api
sudo systemctl status vk-slack-api
curl -k https://localhost:5005/health
```

### Manual Service Recovery
```bash
cd /home/ubuntu/data-uploader
source set_env.sh
nohup python3 main.py > /tmp/api_manual.log 2>&1 &
tail -f /tmp/api_manual.log
```

## Related Documentation
- Infrastructure repo: `/Users/chriscowden/vk-infrastructure`
- Service configs: `/Users/chriscowden/vk-infrastructure/api-server/systemd/`
- Deployment script: `/Users/chriscowden/vk-infrastructure/scripts/deploy-api.sh`