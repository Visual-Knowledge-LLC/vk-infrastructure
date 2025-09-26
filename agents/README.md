# VK Infrastructure Agents

This directory contains specialized agents for managing Visual Knowledge infrastructure components.

## Available Agents

### 1. VK API Server Management Agent
**File**: `vk-api-server-agent.md`
**Purpose**: Manages the VK API Server, including service management, troubleshooting, and monitoring.

## How to Use These Agents

### Method 1: Direct Reference with Claude
Simply tell Claude to use a specific agent:
```
"Use the VK API server management agent to check the service status"
"Follow the vk-api-server-agent to troubleshoot the API"
```

### Method 2: Load Agent Context
Reference the agent documentation directly:
```
"Load /Users/chriscowden/vk-infrastructure/agents/vk-api-server-agent.md and check why the API is down"
```

### Method 3: Use with Task Tool
When using Claude's Task tool for complex operations:
```
"Launch an agent using the vk-api-server-agent documentation to diagnose and fix API issues"
```

### Method 4: Use MCP Tools Directly
The agent documentation shows which MCP tools to use:
```python
# The agent uses this tool internally:
mcp__vk-operations__execute_on_api_server_tool(command="sudo systemctl status api")
```

## Agent Capabilities

### VK API Server Agent
- **Service Management**: Start, stop, restart API services
- **Log Analysis**: View and analyze service logs
- **Health Monitoring**: Check API health endpoints
- **Troubleshooting**: Diagnose and fix common issues
- **Deployment**: Update code and configurations
- **Emergency Recovery**: Reset services when needed

## Best Practices

1. **Always check service status first** when troubleshooting
2. **Use the agent documentation** as a reference guide
3. **Follow the emergency procedures** only when necessary
4. **Keep credentials secure** - use .env files, not hardcoded values

## Quick Commands

### Check API Status
```bash
# Using MCP tool
mcp__vk-operations__execute_on_api_server_tool(command="sudo systemctl status api --no-pager")

# Using SSH directly
~/.ssh/ssh_to_api.sh --command "sudo systemctl status api"
```

### View Recent Logs
```bash
# Using MCP tool
mcp__vk-operations__execute_on_api_server_tool(command="tail -50 /var/log/api_service.log")

# Using SSH directly
~/.ssh/ssh_to_api.sh --command "sudo journalctl -u api -n 100 --no-pager"
```

### Restart Services
```bash
# Using MCP tool
mcp__vk-operations__execute_on_api_server_tool(command="sudo systemctl restart api")

# Using SSH directly
~/.ssh/ssh_to_api.sh --command "sudo systemctl restart api && sudo systemctl restart vk-slack-api"
```

### Health Check
```bash
# Using MCP tool
mcp__vk-operations__execute_on_api_server_tool(command="curl -k https://localhost:5005/health")

# Using SSH directly
curl -k https://api.visualknowledgeportal.com:5005/health
```

## Related Resources

- **Service Configs**: `/api-server/systemd/`
- **Environment Variables**: `/api-server/configs/.env.production`
- **Deployment Script**: `/scripts/deploy-api.sh`
- **SSH Script**: `~/.ssh/ssh_to_api.sh`

## Notes

- The API server hosts two services:
  - `api.service` - Data Uploader API (HTTPS port 5005)
  - `vk-slack-api.service` - Slack API (HTTP port 8347)
- Both services auto-restart on failure
- Credentials are stored in `/home/ubuntu/data-uploader/.env` on the server
- Backup of production .env is at `/api-server/configs/.env.production`