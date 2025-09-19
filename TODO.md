# VK Infrastructure TODO List

## Vision
Transition all VK applications and services to a fully Infrastructure-as-Code (IaC) approach with containerization, automated deployments, and centralized configuration management.

## High Priority - Security & Configuration

### 1. Secrets Management
- [ ] **vk-arcgis-map-tool**: Move hardcoded credentials to AWS Secrets Manager or Parameter Store
  - BBB Partner API Token (currently hardcoded in bbb.py:145)
  - ArcGIS credentials (currently hardcoded in bbb.py:537-539)
- [ ] **All services**: Audit and migrate all hardcoded credentials to secure storage
- [ ] Implement AWS IAM roles for service-to-service authentication
- [ ] Create .env.template files for local development

### 2. Environment Configuration
- [ ] Standardize environment variable naming conventions across all services
- [ ] Document all required environment variables for each service
- [ ] Create terraform modules for managing secrets and parameters

## Infrastructure Components

### 3. Container Orchestration
- [ ] **vk-arcgis-map-tool**: Create Dockerfile and push to ECR
- [ ] Migrate remaining Lambda functions to containerized ECS tasks where appropriate
- [ ] Standardize base Docker images for Python, Node.js services

### 4. API Gateway & Services
- [ ] Debug and document vk-api-server deployment and management
- [ ] Implement health check endpoints for all services
- [ ] Centralize API documentation (OpenAPI/Swagger)

### 5. Monitoring & Logging
- [ ] Implement centralized logging with CloudWatch Logs Insights queries
- [ ] Create CloudWatch dashboards for each service
- [ ] Set up alerting for critical service failures
- [ ] Implement distributed tracing with X-Ray

### 6. CI/CD Pipeline
- [ ] GitHub Actions workflows for automated testing and deployment
- [ ] Implement blue-green deployments for zero-downtime updates
- [ ] Automated rollback on deployment failures

### 7. Database Management
- [ ] Document RDS connection pooling strategy
- [ ] Implement automated backup verification
- [ ] Create database migration scripts and version control

### 8. Service Discovery & Networking
- [ ] Implement AWS Service Discovery for internal services
- [ ] Document and standardize VPC and security group configurations
- [ ] Implement AWS PrivateLink for secure API access

## Application Modernization

### 9. Code Standardization
- [ ] Create shared Python package for common utilities (vk-api-utils expansion)
- [ ] Standardize error handling and logging across all services
- [ ] Implement request retry logic with exponential backoff

### 10. Testing & Quality
- [ ] Add unit tests with minimum 80% coverage requirement
- [ ] Implement integration testing for API endpoints
- [ ] Load testing for critical services

## Documentation

### 11. Operational Runbooks
- [ ] Document disaster recovery procedures
- [ ] Create runbooks for common operational tasks
- [ ] Document service dependencies and architecture diagrams

### 12. Developer Documentation
- [ ] Local development setup guides for each service
- [ ] API documentation with example requests/responses
- [ ] Troubleshooting guides

## Cost Optimization

### 13. Resource Management
- [ ] Implement auto-scaling policies for ECS services
- [ ] Schedule non-production environment shutdowns
- [ ] Regular review of unused resources

## Compliance & Security

### 14. Security Hardening
- [ ] Implement WAF rules for public-facing services
- [ ] Enable AWS GuardDuty and Security Hub
- [ ] Regular security scanning of container images
- [ ] Implement least-privilege IAM policies

## Next Steps
1. Start with secrets management for vk-arcgis-map-tool
2. Debug and document vk-api-server
3. Create Dockerfile for vk-arcgis-map-tool
4. Implement centralized logging

---
*Last Updated: 2025-09-19*
*Maintained by: Chris Cowden*