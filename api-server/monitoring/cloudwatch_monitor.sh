#!/bin/bash

# AWS Configuration
INSTANCE_ID=$(ec2-metadata --instance-id | cut -d " " -f 2)
REGION="us-west-1"
NAMESPACE="VK/API"

# Function to send metric to CloudWatch
send_cloudwatch_metric() {
    local metric_name=$1
    local value=$2
    local unit=${3:-None}

    aws cloudwatch put-metric-data \
        --namespace "$NAMESPACE" \
        --metric-name "$metric_name" \
        --value "$value" \
        --unit "$unit" \
        --dimensions Instance="$INSTANCE_ID" \
        --region "$REGION" \
        --profile vk-prod 2>/dev/null
}

# Check API health
check_api() {
    if curl -k -f -s https://localhost:5005/health > /dev/null 2>&1; then
        send_cloudwatch_metric "APIHealth" 1 Count

        # Get detailed metrics
        metrics=$(curl -k -s https://localhost:5005/health/detailed)
        if [ $? -eq 0 ]; then
            memory_mb=$(echo "$metrics" | jq -r '.metrics.memory_mb // 0')
            cpu_percent=$(echo "$metrics" | jq -r '.metrics.cpu_percent // 0')
            connections=$(echo "$metrics" | jq -r '.metrics.connections // 0')

            send_cloudwatch_metric "MemoryUsage" "$memory_mb" Megabytes
            send_cloudwatch_metric "CPUUtilization" "$cpu_percent" Percent
            send_cloudwatch_metric "ConnectionCount" "$connections" Count
        fi
    else
        send_cloudwatch_metric "APIHealth" 0 Count
    fi
}

# Check nginx
if systemctl is-active nginx > /dev/null 2>&1; then
    send_cloudwatch_metric "NginxHealth" 1 Count
else
    send_cloudwatch_metric "NginxHealth" 0 Count
fi

# Check disk usage
disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
send_cloudwatch_metric "DiskUsagePercent" "$disk_usage" Percent

# Check API
check_api