#!/bin/bash
# Fix nginx configuration for vk-slack-api to strip /slack prefix

set -e

BASTION_HOST="13.52.186.124"
API_SERVER="172.31.0.108"
API_USER="ubuntu"

echo "Fixing nginx configuration for vk-slack-api..."

# Create the corrected nginx configuration
cat << 'EOF' | ssh -o StrictHostKeyChecking=no -o ProxyJump=${API_USER}@${BASTION_HOST} ${API_USER}@${API_SERVER} "sudo tee /etc/nginx/snippets/vk-slack-api.conf > /dev/null"
# VK Slack API proxy configuration
location /slack/ {
    # Remove /slack prefix and pass the rest to the backend
    rewrite ^/slack/(.*) /$1 break;

    proxy_pass http://localhost:8347;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-Host $server_name;
}
EOF

# Update the main nginx configuration to include this snippet
ssh -o StrictHostKeyChecking=no -o ProxyJump=${API_USER}@${BASTION_HOST} ${API_USER}@${API_SERVER} << 'REMOTE_COMMANDS'
# First, remove old incorrect proxy configs for /slack
sudo sed -i '/location \/slack\//,/^[[:space:]]*}/d' /etc/nginx/sites-available/default

# Add include directive for the snippet in both HTTP and HTTPS server blocks
# For HTTP (port 80)
sudo sed -i '/server {/,/^}/ {
  /location \/ {/i\
  # Include VK Slack API configuration\
  include /etc/nginx/snippets/vk-slack-api.conf;
}' /etc/nginx/sites-available/default

# For HTTPS (port 443)
sudo sed -i '/listen 443 ssl/,/^}/ {
  /location \/ {/i\
  # Include VK Slack API configuration\
  include /etc/nginx/snippets/vk-slack-api.conf;
}' /etc/nginx/sites-available/default

# Test nginx configuration
sudo nginx -t

# If test passes, reload nginx
if [ $? -eq 0 ]; then
    sudo systemctl reload nginx
    echo "Nginx configuration updated and reloaded successfully"
else
    echo "Nginx configuration test failed. Please check the configuration."
    exit 1
fi

# Test the endpoint
echo "Testing the corrected endpoint..."
curl -X GET http://localhost:8347/health
echo ""
REMOTE_COMMANDS

# Test from local
echo "Testing from local machine..."
curl -X GET https://api.visualknowledgeportal.com/slack/health 2>/dev/null | python3 -m json.tool || echo "Failed to reach endpoint"

echo "Fix completed!"