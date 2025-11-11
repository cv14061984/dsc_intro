# Quick Start Guide

This guide will help you get the SFTP to Azure Blob Storage integration up and running quickly.

## Prerequisites Checklist

- [ ] MuleSoft Anypoint Studio 7.x or Mule Runtime 4.4.0+
- [ ] Java JDK 8 or higher
- [ ] Maven 3.6.0 or higher
- [ ] SFTP server access (host, port, credentials)
- [ ] Azure Storage Account (account name and key)
- [ ] Azure Blob Storage container created (default name: "target")

## 5-Minute Setup

### Step 1: Configure Properties

Edit `src/main/resources/properties/dev.properties`:

```properties
# SFTP Settings
sftp.host=YOUR_SFTP_HOST
sftp.port=22
sftp.username=YOUR_SFTP_USERNAME
sftp.password=YOUR_SFTP_PASSWORD

# Azure Storage Settings
azure.storage.account.name=YOUR_AZURE_STORAGE_ACCOUNT
azure.storage.account.key=YOUR_AZURE_STORAGE_KEY
azure.storage.container.name=target
```

### Step 2: Create SFTP Directories

On your SFTP server, create these directories:
```bash
/upload/input      # Place CSV files here
/upload/archive    # Successfully processed files
/upload/error      # Failed files
```

### Step 3: Create Azure Container

In Azure Portal:
1. Navigate to your Storage Account
2. Go to "Containers"
3. Create a new container named "target" (or your custom name)
4. Set access level to "Private"

### Step 4: Build & Run

```bash
cd mulesoft-sftp-azure-batch

# Build the project
mvn clean package

# Run locally
mvn mule:run -Denv=dev
```

### Step 5: Test the Integration

#### Option A: Wait for Scheduled Run
The batch job runs daily at 2 AM (configurable in properties).

#### Option B: Manual Trigger
```bash
# Trigger batch job manually
curl -X POST http://localhost:8081/trigger-batch
```

#### Option C: Upload Test File
```bash
# Upload a test CSV to SFTP
sftp your-username@your-sftp-host
cd /upload/input
put test-data.csv
exit
```

## Verify Success

### Check Logs
```bash
tail -f $MULE_HOME/logs/sftp-azure-batch.log
```

Look for:
```
Successfully processed and archived file: test-data.csv
Successfully uploaded file to Azure: test-data.csv
```

### Check Azure Portal
1. Go to Storage Account → Containers → target
2. Verify your CSV file appears
3. Click on the file to download and verify contents

### Check SFTP Archive
```bash
sftp your-username@your-sftp-host
cd /upload/archive
ls
```

Your file should be moved from `input` to `archive`.

## Common First-Time Issues

### Issue: SFTP Connection Failed
**Fix**: Verify firewall allows outbound SSH (port 22)

### Issue: Azure 401 Unauthorized
**Fix**: Verify your Azure storage key is correct and not expired

### Issue: File Not Found
**Fix**: Ensure SFTP working directory is correctly set

### Issue: Scheduler Not Running
**Fix**: Check cron expression and timezone settings

## Next Steps

Once basic setup works:

1. **Security**: Encrypt sensitive properties
   ```bash
   # See README.md section "Secure Properties"
   ```

2. **Production Settings**: Update `prod.properties` with production values

3. **Deploy to CloudHub**: Use deployment scripts
   ```bash
   ./scripts/deploy-cloudhub.sh prod
   ```

4. **Monitor**: Set up alerts in Runtime Manager

5. **Customize**: Adjust batch schedule, file patterns, etc.

## Sample Test CSV

Create `test-data.csv`:
```csv
id,name,email,created_date
1,John Doe,john@example.com,2025-11-11
2,Jane Smith,jane@example.com,2025-11-11
3,Bob Johnson,bob@example.com,2025-11-11
```

## Testing SAS Token

After a file is uploaded, test the SAS URL accessibility:

```bash
# Get the blob URL with SAS token from logs
# It will look like:
# https://youraccount.blob.core.windows.net/target/test-data.csv?sv=2021-08-06&sr=b&...

# Test download
curl -o downloaded-file.csv "FULL_SAS_URL_FROM_LOGS"
```

## Troubleshooting Commands

```bash
# Check if Mule is running
ps aux | grep mule

# Check application status
curl http://localhost:8081/trigger-batch

# View recent logs
tail -n 100 $MULE_HOME/logs/sftp-azure-batch.log

# Test SFTP connection
sftp -v your-username@your-sftp-host

# Check Azure connectivity
curl https://youraccount.blob.core.windows.net/target/?restype=container

# Run MUnit tests
mvn test
```

## Support

- Full documentation: See `README.md`
- Report issues: Create a ticket in your issue tracking system
- Questions: Contact your MuleSoft team lead

## Success Criteria

✅ Application starts without errors
✅ Can connect to SFTP server
✅ Can generate SAS tokens
✅ Can upload to Azure Blob Storage
✅ Files are archived after processing
✅ Logs show successful processing
✅ Can download files from Azure using SAS URL

Once all criteria pass, you're ready for production deployment!
