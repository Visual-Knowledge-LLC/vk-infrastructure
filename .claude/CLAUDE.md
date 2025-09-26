# VK Infrastructure Project Instructions

## Available Agents
When working in this repository, use these specialized agents:

### VK API Server Management Agent
- **Location**: `agents/vk-api-server-agent.md`
- **Purpose**: Complete management of VK API server services
- **Use when**:
  - API server is down or unresponsive
  - Need to check service status or logs
  - Deploying updates to the API server
  - Troubleshooting database connectivity issues
  - Managing SSL certificates

## Quick Commands
```bash
# Check API health
curl -k https://api.visualknowledgeportal.com:5005/health

# Use MCP tool for server management
mcp__vk-operations__execute_on_api_server_tool(command="sudo systemctl status api")

# Direct SSH access
~/.ssh/ssh_to_api.sh --command "sudo systemctl restart api"
```

## Service Information
- **api.service**: Data Uploader API (HTTPS port 5005)
- **vk-slack-api.service**: Slack API (HTTP port 8347)
- **Server**: 172.31.0.108 (via bastion 13.52.186.124)

## Important Files
- Service configs: `api-server/systemd/`
- Production environment: `api-server/configs/.env.production`
- Deployment script: `scripts/deploy-api.sh`
- Agent documentation: `agents/`

## When Issues Arise
1. First check the health endpoint
2. If down, load the agent: `agents/vk-api-server-agent.md`
3. Follow the troubleshooting guide in the agent
4. Use `mcp__vk-operations__execute_on_api_server_tool` for commands