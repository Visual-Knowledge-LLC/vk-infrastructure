# Visual Knowledge Collector Analysis & Automation Plan

**Generated**: September 21, 2025
**Purpose**: Complete inventory of collector repositories and roadmap for CI/CD automation

---

## 📊 Current Collector Repository Status

### **All Collectors - Ready for Production**

| Repository | Location | GitHub Remote | Slack API | Last Updated |
|------------|----------|---------------|-----------|--------------|
| **california-collectors** | `~/california-collectors` | [Link](https://github.com/Visual-Knowledge-LLC/california-collectors.git) | ✅ vk_api_utils | 4 days ago |
| **dc-collectors** | `~/dc-collectors` | [Link](https://github.com/Visual-Knowledge-LLC/dc-collectors.git) | ✅ vk_api_utils | 20 min ago |
| **new-york-collectors** | `~/new-york-collectors` | [Link](https://github.com/Visual-Knowledge-LLC/new-york-collectors.git) | ✅ vk_api_utils | 4 days ago |
| **tennessee_collectors** | `~/Dropbox/.../tennessee_collectors` | [Link](https://github.com/Visual-Knowledge-LLC/tennessee_collectors.git) | ✅ vk_api_utils | 21 min ago |
| **oklahoma_collectors** | `~/Dropbox/.../oklahoma_collectors` | [Link](https://github.com/Visual-Knowledge-LLC/oklahoma_collectors.git) | ✅ vk_api_utils | 21 min ago |
| **nv_collectors** | `~/Dropbox/.../nv_collectors` | [Link](https://github.com/Visual-Knowledge-LLC/nv_collectors.git) | ✅ vk_api_utils | 10 min ago |
| **tucson_data_collection** | `~/Dropbox/.../tucson_data_collection` | [Link](https://github.com/Visual-Knowledge-LLC/tucson_data_collection.git) | ✅ vk_api_utils | 6 min ago |

### **Standard Run Commands**
All repos now use: `python3 run.py [action] --slack=on`

---

## 🔄 Current Manual Process (Friday-Sunday)

**Data Mining Server Commands:**
```bash
# 1. Pull latest changes for each repo
cd /path/to/repo && git pull

# 2. Run collectors with Slack notifications
python3 run.py --slack=on

# 3. Monitor via Slack notifications in #vk-operations
```

**Current Schedule**: Manual execution every Friday-Sunday weekend

---

## 📁 Legacy Data Migration Required

### **Priority Files to Migrate from `vk-server-scrapers`**

#### **California Collectors**
**Source**: `~/Dropbox/.../vk-server-scrapers/california_scrapers/`
**Needed Files**:
- `inputs/` - Input data files (if any exist beyond NY files)
- `agency_map_fixes/` - Agency mapping corrections
- Configuration from `pull_cslb_data_v2.py` and `run_scrapers.py`

#### **New York Collectors**
**Source**: `~/Dropbox/.../vk-server-scrapers/new_york_scrapers/`
**Needed Files**:
- `config/socrata_config.json` - Socrata API configuration
- `config/api_configurations.json` - API endpoint configurations
- `archive/api_field_mapping.json` - Field mapping definitions
- `requirements.txt` - Python dependencies

#### **DC Collectors**
**Source**: `~/Dropbox/.../vk-server-scrapers/dc_scrapers/DPOR/`
**Needed Files**:
- `dpor_Scraper.py` - Core scraper logic to migrate
- `db_connect.py` - Database connection utilities

#### **Shared Utilities**
**Source**: `~/Dropbox/.../vk-server-scrapers/utils/`
**Useful for all repos**:
- `vk_cfg_utils.py` - Configuration utilities
- `vk_date_utils.py` - Date handling utilities
- `vk_file_utils.py` - File operations
- `vk_g_maps.py` - Google Maps integration
- `scraper_progress.py` - Progress tracking (already modernized)

---

## 🚀 CI/CD Automation Roadmap

### **Phase 1: Immediate (This Weekend)**
1. **Data Migration**: Copy essential config/data files from legacy repo
2. **Server Deployment**: Fresh git pull on data_mining server
3. **Manual Run**: Execute this weekend's collection cycle
4. **Document**: Record any missing dependencies or configuration issues

### **Phase 2: Containerization (Next Sprint)**
```bash
# Each collector repo needs:
- Dockerfile
- docker-compose.yml for local testing
- .env.template for configuration
- requirements.txt standardization
```

### **Phase 3: ECS Task Definitions**
```bash
# Infrastructure as Code in vk-infrastructure:
- terraform/ecs-collectors/
- ecs/task-definitions/collectors/
- ECR repositories for each collector
```

### **Phase 4: Scheduled Automation**
```bash
# EventBridge scheduled rules:
- Friday 6PM CT: Start collection cycle
- Saturday 6AM CT: Continue/retry failed collections
- Sunday 6PM CT: Final collection + reporting
```

### **Phase 5: CI/CD Pipeline**
```bash
# GitHub Actions workflows:
- On push to main: Build container → Push to ECR
- Scheduled: Pull latest → Deploy to ECS → Execute
- On failure: Retry logic + enhanced Slack alerting
```

---

## 🎯 Immediate Action Items

### **1. This Weekend's Collection Run**
```bash
# For each collector repo on data_mining server:
git pull origin main
python3 run.py --slack=on

# Repos to run:
- california-collectors
- dc-collectors
- new-york-collectors
- tennessee_collectors
- oklahoma_collectors
- nv_collectors
- tucson_data_collection
```

### **2. Data Migration Tasks**
- [ ] Copy New York config files to `~/new-york-collectors/config/`
- [ ] Copy California agency mappings to `~/california-collectors/config/`
- [ ] Migrate DC DPOR logic to `~/dc-collectors/src/collectors/dpor/`
- [ ] Test each collector with migrated data files

### **3. Infrastructure Preparation**
- [ ] Create Dockerfiles for each collector
- [ ] Add ECS task definitions to `vk-infrastructure/ecs/`
- [ ] Plan ECR repositories and IAM roles
- [ ] Design EventBridge scheduling strategy

---

## 💡 Architecture Vision

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repos  │    │   ECR Registry  │    │  ECS Cluster    │
│                 │    │                 │    │                 │
│ collector-repos │───▶│ Container Images│───▶│ Scheduled Tasks │
│ (vk_api_utils)  │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ GitHub Actions  │    │ Secrets Manager │    │ Slack Webhook   │
│ CI/CD Pipeline  │    │ DB Credentials  │    │ Notifications   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Benefits**:
- **Zero-touch weekends**: Automated Friday-Sunday collection cycles
- **Consistent environments**: Docker containers eliminate "works on my machine"
- **Scalable**: Easy to add new collectors or modify schedules
- **Monitored**: Comprehensive Slack notifications + CloudWatch logs
- **Reliable**: Retry logic, health checks, automated rollbacks

---

## 📋 Next Session Planning

1. **Migrate essential data files** from legacy repo to new collector repos
2. **Test each collector** with migrated configuration
3. **Run weekend collection cycle** on data_mining server
4. **Document any issues** encountered during migration
5. **Plan Dockerfile creation** for containerization phase

This analysis provides the complete roadmap for transitioning from manual weekend collectors to fully automated CI/CD pipeline!