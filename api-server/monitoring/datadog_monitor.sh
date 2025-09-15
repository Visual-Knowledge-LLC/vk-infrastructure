#!/bin/bash

# Datadog API configuration (you'll need to add your API key)
DD_API_KEY="${DD_API_KEY:-YOUR_DATADOG_API_KEY_HERE}"
DD_APP_KEY="${DD_APP_KEY:-YOUR_DATADOG_APP_KEY_HERE}"
DD_SITE="datadoghq.com"  # or datadoghq.eu for EU

# Get instance metadata
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
REGION="us-west-1"

# Function to send metric to Datadog
send_metric() {
    local metric_name=$1
    local metric_value=$2
    local metric_type=${3:-gauge}
    local tags=$4

    current_time=$(date +%s)

    curl -X POST "https://api.${DD_SITE}/api/v1/series" \
        -H "Content-Type: application/json" \
        -H "DD-API-KEY: ${DD_API_KEY}" \
        -d @- <<JSON
{
    "series": [
        {
            "metric": "${metric_name}",
            "points": [[${current_time}, ${metric_value}]],
            "type": "${metric_type}",
            "tags": ["instance:${INSTANCE_ID}", "region:${REGION}", "service:vk-api", ${tags}]
        }
    ]
}
JSON
}

# Check API health and send metrics
check_api_health() {
    # Get health metrics
    response=$(curl -k -s -w "\n%{http_code}" https://localhost:5005/health/metrics)
    http_code=$(echo "$response" | tail -n1)
    metrics=$(echo "$response" | head -n-1)

    if [ "$http_code" = "200" ]; then
        # API is up
        send_metric "vk.api.health.status" 1 gauge

        # Parse and send individual metrics
        echo "$metrics" | jq -r 'to_entries[] | "\(.key) \(.value)"' | while read key value; do
            send_metric "$key" "$value" gauge
        done

        # Log to local file for debugging
        echo "[$(date)] API Health Check: OK" >> /var/log/vk-api/monitor.log
    else
        # API is down
        send_metric "vk.api.health.status" 0 gauge
        echo "[$(date)] API Health Check: FAILED (HTTP $http_code)" >> /var/log/vk-api/monitor.log

        # Send alert event to Datadog
        curl -X POST "https://api.${DD_SITE}/api/v1/events" \
            -H "Content-Type: application/json" \
            -H "DD-API-KEY: ${DD_API_KEY}" \
            -d @- <<JSON
{
    "title": "VK API Server Down",
    "text": "The VK API server on instance ${INSTANCE_ID} is not responding. HTTP Status: ${http_code}",
    "priority": "normal",
    "tags": ["instance:${INSTANCE_ID}", "service:vk-api"],
    "alert_type": "error"
}
JSON
    fi
}

# Check nginx status
check_nginx() {
    if systemctl is-active nginx > /dev/null 2>&1; then
        send_metric "vk.nginx.status" 1 gauge
    else
        send_metric "vk.nginx.status" 0 gauge
    fi
}

# Check disk usage
check_disk() {
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    send_metric "vk.disk.usage.percent" "$disk_usage" gauge

    log_disk_usage=$(df /var/log | awk 'NR==2 {print $5}' | sed 's/%//')
    send_metric "vk.disk.log.usage.percent" "$log_disk_usage" gauge
}

# Main execution
check_api_health
check_nginx
check_disk