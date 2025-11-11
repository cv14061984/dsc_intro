# Deployment Guide - MuleSoft ADLS Finance Integration

## Table of Contents
1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Environment Setup](#environment-setup)
3. [CloudHub Deployment](#cloudhub-deployment)
4. [On-Premise Deployment](#on-premise-deployment)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Rollback Procedure](#rollback-procedure)

## Pre-Deployment Checklist

### Development Environment
- [ ] Code reviewed and approved
- [ ] Unit tests passed
- [ ] Integration tests passed
- [ ] Secure properties encrypted
- [ ] Configuration files updated for DEV
- [ ] README documentation updated

### UAT Environment
- [ ] DEV testing completed
- [ ] UAT configuration files prepared
- [ ] UAT MDM endpoint accessible
- [ ] UAT ADLS account configured
- [ ] Change request approved

### Production Environment
- [ ] UAT testing completed and signed off
- [ ] Production configuration files prepared
- [ ] Production MDM endpoint accessible
- [ ] Production ADLS account configured
- [ ] Change request approved
- [ ] Rollback plan documented
- [ ] Stakeholders notified

## Environment Setup

### 1. Azure Data Lake Storage Setup

```bash
# Create Resource Group (if not exists)
az group create --name gf-finance-rg --location eastus

# Create Storage Account with Data Lake Gen2
az storage account create \
  --name gffinanceprodadls \
  --resource-group gf-finance-rg \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2 \
  --hierarchical-namespace true

# Create Container
az storage container create \
  --name finance-records \
  --account-name gffinanceprodadls

# Get Account Key
az storage account keys list \
  --resource-group gf-finance-rg \
  --account-name gffinanceprodadls \
  --query '[0].value' \
  --output tsv
```

### 2. Encrypt Secure Properties

```bash
# Install MuleSoft Secure Properties Tool
# Download from: https://docs.mulesoft.com/mule-runtime/latest/secure-configuration-properties

# Encrypt ADLS Account Key
java -cp secure-properties-tool.jar \
  com.mulesoft.tools.SecurePropertiesTool \
  string encrypt Blowfish CBC <encryption-key> <adls-account-key>

# Update secure-properties-<env>.yaml with encrypted values
```

### 3. Configure Environment Properties

Edit `src/main/resources/config-prod.yaml`:

```yaml
# Update these values for production
mdm:
  host: "mdm-api.gf.com"  # Production MDM endpoint

adls:
  accountName: "gffinanceprodadls"  # Production ADLS account
  containerName: "finance-records"

error:
  notificationEmail: "finance-ops@gf.com"  # Production notification email
```

## CloudHub Deployment

### Method 1: Maven Plugin (Recommended)

```bash
# Build and Deploy to Development
mvn clean deploy -DmuleDeploy \
  -Denv=dev \
  -Dencryption.key=${ENCRYPTION_KEY} \
  -Dmule.version=4.4.0 \
  -DworkerType=MICRO \
  -Dworkers=1 \
  -DappName=mulesoft-adls-finance-integration-dev

# Deploy to UAT
mvn clean deploy -DmuleDeploy \
  -Denv=uat \
  -Dencryption.key=${ENCRYPTION_KEY} \
  -Dmule.version=4.4.0 \
  -DworkerType=SMALL \
  -Dworkers=1 \
  -DappName=mulesoft-adls-finance-integration-uat

# Deploy to Production
mvn clean deploy -DmuleDeploy \
  -Denv=prod \
  -Dencryption.key=${ENCRYPTION_KEY} \
  -Dmule.version=4.4.0 \
  -DworkerType=SMALL \
  -Dworkers=2 \
  -DappName=mulesoft-adls-finance-integration-prod
```

### Method 2: Anypoint Platform UI

1. **Build the Application**
   ```bash
   mvn clean package
   ```

2. **Login to Anypoint Platform**
   - Navigate to: https://anypoint.mulesoft.com
   - Login with credentials

3. **Deploy Application**
   - Go to Runtime Manager
   - Click "Deploy application"
   - Upload JAR: `target/mulesoft-adls-finance-integration-1.0.0-mule-application.jar`
   - Configure:
     - Application Name: `mulesoft-adls-finance-integration-prod`
     - Deployment Target: CloudHub
     - Runtime Version: 4.4.0
     - Worker Size: SMALL (1 vCore)
     - Workers: 2
     - Region: US East (or nearest to MDM/ADLS)

4. **Set Properties**
   ```
   env=prod
   encryption.key=<your-encryption-key>
   ```

5. **Enable Object Store V2** (Recommended)

6. **Configure Logging**
   - Set log level to WARN for production
   - Enable log forwarding if needed

7. **Click "Deploy Application"**

### Method 3: Anypoint CLI

```bash
# Install Anypoint CLI
npm install -g anypoint-cli

# Login
anypoint-cli runtime-mgr login --username <username> --password <password>

# Deploy
anypoint-cli runtime-mgr cloudhub-application deploy \
  --runtime 4.4.0 \
  --workerSize SMALL \
  --workers 2 \
  --region us-east-1 \
  mulesoft-adls-finance-integration-prod \
  target/mulesoft-adls-finance-integration-1.0.0-mule-application.jar \
  --property env:prod \
  --property encryption.key:<your-encryption-key>
```

## On-Premise Deployment

### Prerequisites
- Mule Runtime 4.4.0 installed
- Java 8 or 11 installed
- Network access to MDM and Azure

### Deployment Steps

1. **Build Application**
   ```bash
   mvn clean package
   ```

2. **Copy JAR to Mule Apps Directory**
   ```bash
   cp target/mulesoft-adls-finance-integration-1.0.0-mule-application.jar \
      $MULE_HOME/apps/
   ```

3. **Set Environment Variables**

   **Linux/Mac:**
   ```bash
   export env=prod
   export encryption.key=<your-encryption-key>
   ```

   **Windows:**
   ```cmd
   set env=prod
   set encryption.key=<your-encryption-key>
   ```

4. **Start Mule Runtime**
   ```bash
   $MULE_HOME/bin/mule start
   ```

5. **Monitor Deployment**
   ```bash
   tail -f $MULE_HOME/logs/mule_ee.log
   ```

   Look for:
   ```
   INFO  [WrapperListener_start_runner] ... Application started successfully
   ```

### Using Wrapper Configuration (Alternative)

Edit `$MULE_HOME/conf/wrapper.conf`:

```properties
# Add environment properties
wrapper.java.additional.20=-Denv=prod
wrapper.java.additional.21=-Dencryption.key=<your-encryption-key>
```

Restart Mule:
```bash
$MULE_HOME/bin/mule restart
```

## Post-Deployment Verification

### 1. Health Check

```bash
# Check ADLS Health
curl -X GET https://<app-url>/api/system/adls/health

# Expected Response:
{
  "status": "UP",
  "service": "sys-adls-financerecords-gf-app",
  "timestamp": "2025-11-11T10:30:00Z",
  "adls": {
    "accountName": "gffinanceprodadls",
    "containerName": "finance-records",
    "connected": true
  }
}
```

### 2. Manual Sync Test

```bash
# Trigger manual sync
curl -X GET https://<app-url>/api/experience/company-file/sync

# Expected Response:
{
  "status": "SUCCESS",
  "message": "Company file sync completed successfully",
  "correlationId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2025-11-11T10:30:00Z",
  "processingTime": "5432ms",
  "recordsProcessed": 150
}
```

### 3. Verify Scheduler

Check logs to confirm scheduler is configured:
```bash
# CloudHub
# Go to Runtime Manager > Application > Logs

# On-Premise
tail -f $MULE_HOME/logs/mulesoft-adls-finance-integration.log | grep SCHEDULER
```

Look for:
```
INFO [scheduler-thread-1] [correlation-id] com.gf.finance: [SCHEDULER] Starting company file sync
```

### 4. Verify ADLS File Creation

```bash
# Using Azure CLI
az storage blob list \
  --account-name gffinanceprodadls \
  --container-name finance-records \
  --prefix company-files/ \
  --output table
```

### 5. Monitor for Errors

Monitor application for 24 hours post-deployment:
- Check logs hourly for first 6 hours
- Verify scheduler executions
- Monitor error rate
- Check ADLS file creation

## Rollback Procedure

### CloudHub Rollback

#### Method 1: Redeploy Previous Version via UI
1. Login to Anypoint Platform
2. Go to Runtime Manager > Applications
3. Select application
4. Click "Settings" > "Redeploy"
5. Upload previous version JAR
6. Click "Deploy"

#### Method 2: Anypoint CLI
```bash
anypoint-cli runtime-mgr cloudhub-application modify \
  --runtime 4.4.0 \
  mulesoft-adls-finance-integration-prod \
  target/mulesoft-adls-finance-integration-<previous-version>-mule-application.jar
```

### On-Premise Rollback

1. **Stop Application**
   ```bash
   # CloudHub: Stop via Runtime Manager UI

   # On-Premise:
   touch $MULE_HOME/apps/mulesoft-adls-finance-integration-1.0.0-mule-application.jar.stop
   ```

2. **Remove Current Version**
   ```bash
   rm $MULE_HOME/apps/mulesoft-adls-finance-integration-1.0.0-mule-application.jar
   ```

3. **Deploy Previous Version**
   ```bash
   cp backup/mulesoft-adls-finance-integration-<previous-version>-mule-application.jar \
      $MULE_HOME/apps/
   ```

4. **Verify Rollback**
   ```bash
   tail -f $MULE_HOME/logs/mule_ee.log
   ```

## Deployment Schedule Recommendation

### Development
- Deploy: Anytime during business hours
- Notification: Development team only

### UAT
- Deploy: During off-peak hours (6 PM - 8 PM IST)
- Notification: QA team, Business users

### Production
- Deploy: During maintenance window (Saturday 11 PM - Sunday 2 AM IST)
- Notification: All stakeholders, Operations team, Finance team
- Approval: Change Advisory Board (CAB)

## Environment-Specific Worker Configuration

| Environment | Worker Type | Workers | Region      | Auto-Scale |
|-------------|-------------|---------|-------------|------------|
| DEV         | MICRO       | 1       | US East     | No         |
| UAT         | SMALL       | 1       | US East     | No         |
| PROD        | SMALL       | 2       | US East     | Yes (2-4)  |

## Monitoring and Alerts

### CloudHub Alerts (Recommended)

Configure alerts in Runtime Manager:

1. **Application Down**
   - Metric: Application Status
   - Condition: Status is not "Running"
   - Action: Email to finance-ops@gf.com

2. **High Error Rate**
   - Metric: Error Count
   - Condition: > 10 errors in 5 minutes
   - Action: Email + SMS

3. **Worker CPU High**
   - Metric: CPU Usage
   - Condition: > 80% for 10 minutes
   - Action: Email to devops@gf.com

### Log Monitoring

Set up log aggregation:
- CloudHub: Enable log forwarding to Splunk/ELK
- On-Premise: Configure log4j2 to send to centralized logging

## Support Contacts

- **Development Issues**: dev-team@gf.com
- **Deployment Support**: devops@gf.com
- **Business Issues**: finance-ops@gf.com
- **Infrastructure**: infrastructure@gf.com
- **24/7 On-Call**: +1-XXX-XXX-XXXX

## Deployment Checklist

Print and complete this checklist for each deployment:

```
[ ] Pre-deployment tasks completed
[ ] Configuration files updated
[ ] Secure properties encrypted
[ ] Build successful (mvn clean package)
[ ] Deployment executed
[ ] Health check passed
[ ] Manual sync test passed
[ ] Scheduler verified
[ ] ADLS file creation verified
[ ] Logs monitored
[ ] Stakeholders notified
[ ] Deployment documented
[ ] Rollback plan ready
```

## Revision History

| Version | Date       | Author           | Changes           |
|---------|------------|------------------|-------------------|
| 1.0     | 2025-11-11 | Development Team | Initial release   |
