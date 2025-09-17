#!/bin/bash

# Create Application Load Balancer for VK Slack API

set -e

AWS_REGION="us-west-1"
AWS_PROFILE="vk-prod"

echo "Creating Application Load Balancer for VK Slack API..."

# 1. Get VPC and Subnet information
VPC_ID=$(aws ec2 describe-vpcs --region $AWS_REGION --filters "Name=is-default,Values=true" --query 'Vpcs[0].VpcId' --output text)
echo "VPC ID: $VPC_ID"

# Get public subnets
SUBNET_1=$(aws ec2 describe-subnets --region $AWS_REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=availability-zone,Values=us-west-1a" --query 'Subnets[0].SubnetId' --output text)
SUBNET_2=$(aws ec2 describe-subnets --region $AWS_REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=availability-zone,Values=us-west-1c" --query 'Subnets[0].SubnetId' --output text)
echo "Subnets: $SUBNET_1, $SUBNET_2"

# 2. Create Security Group for ALB
SG_ID=$(aws ec2 create-security-group \
    --group-name vk-slack-api-alb-sg \
    --description "Security group for VK Slack API ALB" \
    --vpc-id $VPC_ID \
    --region $AWS_REGION \
    --output text --query 'GroupId' 2>/dev/null || \
    aws ec2 describe-security-groups --region $AWS_REGION --filters "Name=group-name,Values=vk-slack-api-alb-sg" --query 'SecurityGroups[0].GroupId' --output text)

echo "Security Group: $SG_ID"

# Allow HTTP and HTTPS from anywhere
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $AWS_REGION 2>/dev/null || true
aws ec2 authorize-security-group-ingress --group-id $SG_ID --protocol tcp --port 443 --cidr 0.0.0.0/0 --region $AWS_REGION 2>/dev/null || true

# 3. Create Target Group
TG_ARN=$(aws elbv2 create-target-group \
    --name vk-slack-api-tg \
    --protocol HTTP \
    --port 8000 \
    --vpc-id $VPC_ID \
    --target-type ip \
    --health-check-enabled \
    --health-check-path /health \
    --health-check-protocol HTTP \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 10 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --region $AWS_REGION \
    --output text --query 'TargetGroups[0].TargetGroupArn' 2>/dev/null || \
    aws elbv2 describe-target-groups --names vk-slack-api-tg --region $AWS_REGION --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "Target Group ARN: $TG_ARN"

# 4. Create Application Load Balancer
ALB_ARN=$(aws elbv2 create-load-balancer \
    --name vk-slack-api-alb \
    --subnets $SUBNET_1 $SUBNET_2 \
    --security-groups $SG_ID \
    --scheme internet-facing \
    --type application \
    --ip-address-type ipv4 \
    --region $AWS_REGION \
    --output text --query 'LoadBalancers[0].LoadBalancerArn' 2>/dev/null || \
    aws elbv2 describe-load-balancers --names vk-slack-api-alb --region $AWS_REGION --query 'LoadBalancers[0].LoadBalancerArn' --output text)

echo "ALB ARN: $ALB_ARN"

# Get ALB DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB_ARN --region $AWS_REGION --query 'LoadBalancers[0].DNSName' --output text)
echo "ALB DNS: $ALB_DNS"

# 5. Create Listener
LISTENER_ARN=$(aws elbv2 create-listener \
    --load-balancer-arn $ALB_ARN \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=forward,TargetGroupArn=$TG_ARN \
    --region $AWS_REGION \
    --output text --query 'Listeners[0].ListenerArn' 2>/dev/null || \
    aws elbv2 describe-listeners --load-balancer-arn $ALB_ARN --region $AWS_REGION --query 'Listeners[0].ListenerArn' --output text)

echo "Listener ARN: $LISTENER_ARN"

# 6. Update ECS Service to use the Target Group
echo "Updating ECS service to register with target group..."
aws ecs update-service \
    --cluster ProdVKServices \
    --service vk-slack-api \
    --load-balancers targetGroupArn=$TG_ARN,containerName=vk-slack-api,containerPort=8000 \
    --region $AWS_REGION

echo ""
echo "=========================================="
echo "ALB Created Successfully!"
echo "ALB DNS: $ALB_DNS"
echo "Test URL: http://$ALB_DNS/health"
echo ""
echo "To set up a custom domain:"
echo "1. Create a CNAME record: slack-api.visualknowledgeportal.com -> $ALB_DNS"
echo "2. Or create an A record with Route53 alias to the ALB"
echo "=========================================="