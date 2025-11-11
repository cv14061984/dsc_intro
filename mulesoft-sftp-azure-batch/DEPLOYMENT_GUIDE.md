# Deployment Guide

Complete guide for deploying the SFTP to Azure Batch Integration across different environments.

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Local Development Deployment](#local-development-deployment)
3. [CloudHub Deployment](#cloudhub-deployment)
4. [On-Premise Deployment](#on-premise-deployment)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Rollback Procedures](#rollback-procedures)
7. [Troubleshooting](#troubleshooting)

## Pre-Deployment Checklist

### Infrastructure Requirements

#### SFTP Server
- [ ] SFTP server accessible from deployment environment
- [ ] Credentials created and tested
- [ ] Required directories exist:
  - `/upload/input`
  - `/upload/archive`
  - `/upload/error`
  - `/upload/processing` (optional)
- [ ] Write permissions verified
- [ ] Firewall rules configured (port 22)

#### Azure Storage
- [ ] Storage account created
- [ ] Container "target" (or custom name) exists
- [ ] Storage account key obtained
- [ ] Network access configured (allow from deployment IPs)
- [ ] HTTPS access verified

#### MuleSoft Platform
- [ ] Anypoint Platform account active
- [ ] Appropriate environment created (Dev/QA/Prod)
- [ ] CloudHub vCores available (if deploying to CloudHub)
- [ ] Runtime Manager permissions granted

### Configuration

- [ ] Properties files configured for target environment
- [ ] Sensitive credentials encrypted (production)
- [ ] Scheduler cron expression validated
- [ ] File patterns tested
- [ ] Log levels appropriate for environment
- [ ] Time zone configured correctly

### Testing

- [ ] Unit tests passing (`mvn test`)
- [ ] Integration tests completed
- [ ] Manual test file successfully processed
- [ ] SAS token generation verified
- [ ] Azure upload confirmed
- [ ] File archiving working
- [ ] Error handling tested

## Local Development Deployment

### Option 1: Using Anypoint Studio

1. **Import Project**
   ```
   File → Import → Anypoint Studio → Packaged mule application (.jar)
   ```

2. **Configure Run Configuration**
   - Right-click project → Run As → Run Configurations
   - Arguments tab → VM arguments:
     ```
     -Denv=dev
     -Dencryption.key=your_encryption_key
     ```

3. **Run Application**
   - Click "Run"
   - Monitor Console for startup logs

4. **Verify**
   ```
   http://localhost:8081/trigger-batch
   ```

### Option 2: Using Maven

1. **Set Environment**
   ```bash
   export MULE_ENV=dev
   export ENCRYPTION_KEY=your_encryption_key
   ```

2. **Run Application**
   ```bash
   cd mulesoft-sftp-azure-batch
   mvn clean mule:run -Denv=dev
   ```

3. **Verify**
   - Check logs: `logs/sftp-azure-batch.log`
   - Test endpoint: `curl -X POST http://localhost:8081/trigger-batch`

### Option 3: Using Deployment Script

1. **Ensure MULE_HOME is set**
   ```bash
   export MULE_HOME=/path/to/mule/runtime
   ```

2. **Run Deployment Script**
   ```bash
   ./scripts/deploy-local.sh dev
   ```

3. **Monitor Deployment**
   ```bash
   tail -f $MULE_HOME/logs/sftp-azure-batch.log
   ```

## CloudHub Deployment

### Option 1: Using Deployment Script (Recommended)

1. **Set Credentials**
   ```bash
   export ANYPOINT_USERNAME=your_username
   export ANYPOINT_PASSWORD=your_password
   ```

2. **Deploy to Target Environment**
   ```bash
   # Development
   ./scripts/deploy-cloudhub.sh dev

   # QA
   ./scripts/deploy-cloudhub.sh qa

   # Production
   ./scripts/deploy-cloudhub.sh prod
   ```

3. **Monitor Deployment**
   - Login to Anypoint Platform
   - Navigate to Runtime Manager
   - Select your application
   - View deployment progress

### Option 2: Using Maven Command

```bash
mvn clean deploy -DmuleDeploy \
  -Danypoint.username=YOUR_USERNAME \
  -Danypoint.password=YOUR_PASSWORD \
  -Denv=prod \
  -DapplicationName=sftp-azure-batch-prod \
  -Denvironment=Production \
  -Dregion=us-east-2 \
  -DworkerType=SMALL \
  -Dworkers=2 \
  -DmuleVersion=4.4.0 \
  -DobjectStoreV2=true
```

### Option 3: Using Anypoint Platform UI

1. **Build Application Package**
   ```bash
   mvn clean package -DskipTests -Denv=prod
   ```

2. **Login to Anypoint Platform**
   - Navigate to https://anypoint.mulesoft.com
   - Go to Runtime Manager

3. **Deploy Application**
   - Click "Deploy application"
   - Application Name: `sftp-azure-batch-prod`
   - Deployment Target: CloudHub
   - Runtime Version: 4.4.0
   - Upload JAR: `target/sftp-azure-batch-integration-1.0.0-mule-application.jar`

4. **Configure Runtime**
   - Region: Select appropriate region
   - Worker Size: SMALL (production) or MICRO (dev/qa)
   - Workers: 2 (production) or 1 (dev/qa)
   - Object Store: V2 (enabled)

5. **Set Properties**
   Add application properties:
   ```properties
   env=prod
   encryption.key=your_encryption_key
   ```

6. **Deploy**
   - Click "Deploy Application"
   - Wait for deployment to complete

### CloudHub Configuration Recommendations

| Environment | Worker Type | Workers | Region      |
|-------------|-------------|---------|-------------|
| Development | MICRO       | 1       | us-east-2   |
| QA          | MICRO       | 1       | us-east-2   |
| Production  | SMALL       | 2       | us-east-2   |

## On-Premise Deployment

### Prerequisites

- Mule Runtime 4.4.0+ installed
- License key configured
- Network connectivity to SFTP and Azure

### Deployment Steps

1. **Build Application**
   ```bash
   mvn clean package -DskipTests -Denv=prod
   ```

2. **Copy to Mule Runtime**
   ```bash
   cp target/sftp-azure-batch-integration-1.0.0-mule-application.jar \
      $MULE_HOME/apps/
   ```

3. **Configure System Properties**

   Edit `$MULE_HOME/conf/wrapper.conf`:
   ```properties
   wrapper.java.additional.10=-Denv=prod
   wrapper.java.additional.11=-Dencryption.key=your_encryption_key
   ```

4. **Start Mule Runtime**
   ```bash
   $MULE_HOME/bin/mule start
   ```

5. **Verify Deployment**
   ```bash
   tail -f $MULE_HOME/logs/mule_ee.log
   tail -f $MULE_HOME/logs/sftp-azure-batch.log
   ```

### Automatic Deployment (Hot Deployment)

Mule automatically deploys applications placed in the `apps` directory:

```bash
# Watch for deployment
watch -n 1 'ls -lh $MULE_HOME/apps/'

# Check deployment status
ls -lh $MULE_HOME/apps/*.txt
```

Deployment complete when you see:
- `sftp-azure-batch-integration-anchor.txt` created

## Post-Deployment Verification

### Automated Verification

Run verification script:
```bash
./scripts/verify-deployment.sh [env]
```

### Manual Verification Steps

#### 1. Application Health Check

**CloudHub:**
```bash
# Check application status
curl -X GET https://anypoint.mulesoft.com/cloudhub/api/v2/applications/sftp-azure-batch-prod \
  -H "Authorization: Bearer YOUR_TOKEN"
```

**On-Premise:**
```bash
curl -X POST http://localhost:8081/trigger-batch
```

#### 2. SFTP Connectivity

```bash
# Place test file
echo "id,name,value\n1,test,100" > test.csv
sftp user@sftp-host <<EOF
cd /upload/input
put test.csv
exit
EOF
```

#### 3. Monitor Logs

**CloudHub:**
- Runtime Manager → Application → Logs

**On-Premise:**
```bash
tail -f $MULE_HOME/logs/sftp-azure-batch.log | grep -i "error\|success\|processed"
```

#### 4. Verify Azure Upload

```bash
# Azure CLI
az storage blob list \
  --account-name yourstorageaccount \
  --container-name target \
  --output table
```

#### 5. Check File Archiving

```bash
sftp user@sftp-host <<EOF
cd /upload/archive
ls -la
exit
EOF
```

### Health Check Checklist

- [ ] Application status: Started
- [ ] No errors in startup logs
- [ ] SFTP connection successful
- [ ] Azure connection successful
- [ ] Test file processed successfully
- [ ] File archived correctly
- [ ] Scheduler configured and active
- [ ] Manual trigger endpoint responding
- [ ] SAS token generation working
- [ ] Monitoring/alerts configured

## Rollback Procedures

### CloudHub Rollback

#### Option 1: Redeploy Previous Version

1. **In Runtime Manager:**
   - Select application
   - Click "Redeploy"
   - Choose previous version
   - Click "Redeploy"

2. **Using Maven:**
   ```bash
   # Deploy previous version
   mvn deploy -DmuleDeploy -Danypoint.username=USER -Danypoint.password=PASS
   ```

#### Option 2: Manual Upload

1. Get previous JAR from artifact repository
2. Runtime Manager → Choose File → Upload previous JAR
3. Deploy

### On-Premise Rollback

```bash
# Stop Mule
$MULE_HOME/bin/mule stop

# Remove current deployment
rm $MULE_HOME/apps/sftp-azure-batch-integration-*.jar
rm -rf $MULE_HOME/apps/sftp-azure-batch-integration-anchor.txt

# Deploy previous version
cp /backup/sftp-azure-batch-integration-OLD.jar $MULE_HOME/apps/

# Start Mule
$MULE_HOME/bin/mule start
```

### Rollback Verification

After rollback:
- [ ] Application started successfully
- [ ] Previous configuration active
- [ ] Test file processes correctly
- [ ] No errors in logs
- [ ] Stakeholders notified

## Troubleshooting

### Deployment Fails

**Symptom:** Application fails to deploy

**Possible Causes:**
1. Invalid configuration
2. Missing dependencies
3. Insufficient resources

**Solutions:**
```bash
# Check logs
tail -f $MULE_HOME/logs/mule_ee.log

# Verify configuration
mvn validate

# Check available memory
free -h

# Verify CloudHub resources
# Check vCore availability in Runtime Manager
```

### Application Starts But Doesn't Process Files

**Check:**
1. Scheduler configuration
2. SFTP connectivity
3. File permissions
4. File pattern matching

**Debug:**
```bash
# Manual trigger
curl -X POST http://localhost:8081/trigger-batch

# Check SFTP connection
sftp -v user@sftp-host

# Verify cron expression
# Use: https://crontab.guru/
```

### Azure Upload Failures

**Check:**
1. Storage account key validity
2. Container existence
3. Network connectivity
4. SAS token generation

**Debug:**
```bash
# Test Azure connectivity
curl https://youraccount.blob.core.windows.net/target/?restype=container

# Verify SAS token in logs
grep "SAS token generated" logs/sftp-azure-batch.log
```

## Deployment Best Practices

1. **Always deploy to lower environments first**
   - Dev → QA → Production

2. **Use CI/CD pipelines**
   - Automate testing and deployment
   - See `.github/workflows/ci-cd.yml`

3. **Backup before deployment**
   ```bash
   cp target/current.jar backup/current-$(date +%Y%m%d).jar
   ```

4. **Deploy during maintenance windows**
   - Production: Off-peak hours
   - Notify stakeholders

5. **Monitor post-deployment**
   - Watch logs for 24 hours
   - Verify first scheduled run
   - Check metrics in Runtime Manager

6. **Document deployments**
   - Version deployed
   - Date/time
   - Issues encountered
   - Rollback performed (if any)

## Support Contacts

- **Technical Issues:** support@example.com
- **CloudHub Issues:** MuleSoft Support Portal
- **Emergency Rollback:** On-call engineer

## Additional Resources

- [MuleSoft Documentation](https://docs.mulesoft.com)
- [CloudHub Documentation](https://docs.mulesoft.com/runtime-manager/cloudhub)
- [Azure Blob Storage](https://docs.microsoft.com/azure/storage/blobs/)
