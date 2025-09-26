#!/bin/bash
# Deploy API Server Configuration

set -e

BASTION_HOST="ec2-user@13.52.186.124"
API_HOST="ubuntu@172.31.0.108"
REPO_DIR="$(dirname $(dirname $(realpath $0)))"

echo "🚀 Deploying VK API Server Configuration"
echo "========================================="

# Function to execute commands on API server via bastion
exec_on_api() {
    ssh -o StrictHostKeyChecking=no $BASTION_HOST "ssh $API_HOST '$1'"
}

# Function to copy files to API server via bastion
copy_to_api() {
    local src=$1
    local dest=$2
    echo "📦 Copying $src to $dest"
    cat $src | ssh -o StrictHostKeyChecking=no $BASTION_HOST \
        "ssh $API_HOST 'sudo tee $dest > /dev/null'"
}

# Deploy systemd services
echo "1️⃣ Deploying systemd services..."
copy_to_api "$REPO_DIR/api-server/systemd/api.service" "/etc/systemd/system/api.service"
copy_to_api "$REPO_DIR/api-server/systemd/vk-slack-api.service" "/etc/systemd/system/vk-slack-api.service"
exec_on_api "sudo systemctl daemon-reload"

# Deploy nginx configuration
echo "2️⃣ Deploying nginx configuration..."
copy_to_api "$REPO_DIR/api-server/nginx/vk-api.conf" "/etc/nginx/sites-available/vk-api"
exec_on_api "sudo nginx -t && sudo systemctl reload nginx"

# Deploy logrotate configuration
echo "3️⃣ Deploying log rotation configuration..."
copy_to_api "$REPO_DIR/api-server/logs/logrotate.conf" "/etc/logrotate.d/vk-api"

# Deploy monitoring scripts
echo "4️⃣ Deploying monitoring scripts..."
for script in $REPO_DIR/api-server/monitoring/*.sh; do
    if [ -f "$script" ]; then
        filename=$(basename "$script")
        copy_to_api "$script" "/home/ubuntu/data-uploader/$filename"
        exec_on_api "sudo chmod +x /home/ubuntu/data-uploader/$filename"
    fi
done

# Deploy health check module if exists
if [ -f "$REPO_DIR/api-server/app/health_check.py" ]; then
    echo "5️⃣ Deploying health check module..."
    copy_to_api "$REPO_DIR/api-server/app/health_check.py" "/home/ubuntu/data-uploader/health_check.py"
fi

# Deploy cron jobs
if [ -f "$REPO_DIR/api-server/monitoring/cron.d/vk-api-monitoring" ]; then
    echo "6️⃣ Deploying cron jobs..."
    copy_to_api "$REPO_DIR/api-server/monitoring/cron.d/vk-api-monitoring" "/etc/cron.d/vk-api-monitoring"
fi

# Restart services
echo "7️⃣ Restarting API services..."
exec_on_api "sudo systemctl restart api"
exec_on_api "sudo systemctl restart vk-slack-api"
sleep 5

# Check status
echo "8️⃣ Checking service status..."
exec_on_api "sudo systemctl status api --no-pager"
exec_on_api "sudo systemctl status vk-slack-api --no-pager"

# Health check
echo "9️⃣ Running health checks..."
exec_on_api "curl -k -s https://localhost:5005/health | jq '.'"
exec_on_api "curl -s http://localhost:8347/health | jq '.'"

echo "✅ Deployment complete!"