# SFTP to Azure Blob Storage Batch Integration

## Overview

This is a production-ready MuleSoft application that performs daily batch transfers of CSV files from an SFTP server to Azure Blob Storage. The application generates short-lived SAS (Shared Access Signature) tokens dynamically for secure document accessibility in Azure Blob Storage.

## Features

- **Scheduled Daily Batch Processing**: Runs automatically using a configurable cron scheduler
- **SFTP Integration**: Reads CSV files from SFTP input directory
- **Dynamic SAS Token Generation**: Creates short-lived, secure tokens for Azure Blob Storage access
- **Azure Blob Storage Upload**: Transfers files to Azure using REST API with SAS authentication
- **Automatic File Archiving**: Moves successfully processed files to archive directory
- **Error Handling**: Moves failed files to error directory with comprehensive logging
- **Environment-Specific Configuration**: Supports dev, qa, and prod environments
- **Retry Logic**: Automatic retry mechanism for transient failures
- **Production-Ready Logging**: Comprehensive logging with log rotation
- **Manual Trigger**: HTTP endpoint for manual batch job execution
- **MUnit Tests**: Automated testing for critical components

## Architecture

### Flow Components

1. **Scheduler Flow** (`scheduler-daily-batch-flow`)
   - Triggers daily at configured time (default: 2 AM)
   - Initializes batch processing
   - Tracks success/error counts

2. **Process SFTP Files Flow** (`process-sftp-files-flow`)
   - Lists CSV files in SFTP input directory
   - Iterates through each file for processing

3. **Process Single File Flow** (`process-single-file-flow`)
   - Reads file from SFTP
   - Generates SAS token
   - Uploads to Azure
   - Archives or moves to error directory

4. **Generate SAS Token Flow** (`generate-sas-token-flow`)
   - Invokes Java utility to create Azure SAS token
   - Token validity: configurable (default 30-60 minutes)

5. **Upload to Azure Flow** (`upload-to-azure-blob-flow`)
   - Uses HTTP PUT with SAS token
   - Uploads file to Azure Blob Storage container

6. **Manual Trigger Flow** (`manual-trigger-flow`)
   - HTTP endpoint for testing: POST to `http://localhost:8081/trigger-batch`

## Directory Structure

```
mulesoft-sftp-azure-batch/
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/example/mulesoft/azure/
│   │   │       └── AzureSASTokenGenerator.java
│   │   ├── mule/
│   │   │   ├── mule-artifact.json
│   │   │   └── sftp-azure-batch-integration.xml
│   │   └── resources/
│   │       ├── config/
│   │       │   └── global-config.xml
│   │       ├── properties/
│   │       │   ├── dev.properties
│   │       │   ├── qa.properties
│   │       │   └── prod.properties
│   │       └── log4j2.xml
│   └── test/
│       └── munit/
│           └── sftp-azure-batch-test-suite.xml
└── pom.xml
```

## Prerequisites

- **MuleSoft Runtime**: Mule 4.4.0 or higher
- **Java**: JDK 1.8 or higher
- **Maven**: 3.6.0 or higher
- **SFTP Server Access**: Host, port, username, password
- **Azure Storage Account**: Account name, account key, container created

## Configuration

### Environment Variables

Set the `env` variable to specify the environment:
- `dev` (Development)
- `qa` (Quality Assurance)
- `prod` (Production)

In Anypoint Studio:
```
-Denv=dev
```

In CloudHub:
Set as application property: `env=prod`

### SFTP Configuration

Edit `src/main/resources/properties/{env}.properties`:

```properties
sftp.host=sftp.example.com
sftp.port=22
sftp.username=your_username
sftp.password=your_password
sftp.input.directory=/upload/input
sftp.archive.directory=/upload/archive
sftp.error.directory=/upload/error
```

### Azure Storage Configuration

```properties
azure.storage.account.name=yourstorageaccount
azure.storage.account.key=your_base64_encoded_key
azure.storage.container.name=target
azure.sas.token.expiry.minutes=60
azure.sas.permissions=racwdl
```

**SAS Permissions Explained:**
- `r` - Read
- `a` - Add
- `c` - Create
- `w` - Write
- `d` - Delete
- `l` - List

### Scheduler Configuration

```properties
# Cron expression for daily at 2 AM EST
scheduler.cron.expression=0 0 2 * * ?
scheduler.time.zone=America/New_York
```

## Installation & Deployment

### Local Development

1. **Clone the repository**:
   ```bash
   cd mulesoft-sftp-azure-batch
   ```

2. **Update configuration**:
   Edit `src/main/resources/properties/dev.properties` with your credentials

3. **Build the application**:
   ```bash
   mvn clean package
   ```

4. **Run in Anypoint Studio**:
   - Import project into Anypoint Studio
   - Set VM argument: `-Denv=dev`
   - Run the application

5. **Run standalone**:
   ```bash
   mvn mule:run -Denv=dev
   ```

### CloudHub Deployment

1. **Configure CloudHub settings in pom.xml**:
   ```xml
   <cloudHubDeployment>
       <uri>https://anypoint.mulesoft.com</uri>
       <muleVersion>4.4.0</muleVersion>
       <applicationName>sftp-azure-batch-integration</applicationName>
       <environment>Production</environment>
       <region>us-east-2</region>
       <workers>1</workers>
       <workerType>MICRO</workerType>
   </cloudHubDeployment>
   ```

2. **Deploy using Maven**:
   ```bash
   mvn clean deploy -DmuleDeploy \
     -Danypoint.username=your_username \
     -Danypoint.password=your_password \
     -Denv=prod
   ```

3. **Deploy via Anypoint Platform**:
   - Build deployable archive: `mvn clean package`
   - Upload JAR from `target/` directory
   - Configure properties in Runtime Manager

### On-Premise Deployment

1. **Build the application**:
   ```bash
   mvn clean package
   ```

2. **Copy to Mule runtime**:
   ```bash
   cp target/sftp-azure-batch-integration-1.0.0-mule-application.jar \
      $MULE_HOME/apps/
   ```

3. **Configure environment**:
   Set system property or update wrapper.conf:
   ```
   wrapper.java.additional.10=-Denv=prod
   ```

## Testing

### Run MUnit Tests

```bash
mvn clean test
```

### Manual Testing

1. **Start the application**

2. **Trigger batch manually**:
   ```bash
   curl -X POST http://localhost:8081/trigger-batch
   ```

3. **Check logs**:
   ```bash
   tail -f $MULE_HOME/logs/sftp-azure-batch.log
   ```

4. **Upload test file to SFTP**:
   ```bash
   sftp user@sftp-server
   cd /upload/input
   put test-file.csv
   ```

5. **Verify in Azure**:
   - Check Azure portal for file in target container
   - Test SAS URL accessibility

## Monitoring & Operations

### Key Metrics to Monitor

- Batch job execution time
- Success/failure rate
- File processing throughput
- Azure API response times
- SFTP connection health

### Log Files

- **Application Log**: `$MULE_HOME/logs/sftp-azure-batch.log`
- **Console Output**: stdout (CloudHub logs)

### Log Levels

Configure in properties:
```properties
log.level=INFO  # DEBUG, INFO, WARN, ERROR
```

### Alerts & Notifications

Set up alerts for:
- Batch job failures
- Azure upload errors
- SFTP connection failures
- SAS token generation failures

## Security Best Practices

### Secure Properties

1. **Encrypt sensitive data**:
   ```bash
   java -cp $MULE_HOME/lib/standalone/mule-secure-configuration-property-module-*.jar \
     com.mulesoft.modules.configuration.property.secure.tool.Main \
     string encrypt Blowfish CBC your_key "sensitive_value"
   ```

2. **Use encrypted values in properties**:
   ```properties
   sftp.password=![encrypted_value]
   azure.storage.account.key=![encrypted_value]
   ```

3. **Set encryption key**:
   ```
   -Dencryption.key=your_encryption_key
   ```

### Network Security

- Use HTTPS for Azure connections (enforced)
- Use SFTP (SSH) for file transfers
- Restrict CloudHub IP addresses in firewalls
- Use VPN for on-premise connectivity

### Access Control

- Use least-privilege principle for SFTP accounts
- Limit SAS token permissions to minimum required
- Use short-lived SAS tokens (30-60 minutes)
- Rotate credentials regularly

## Troubleshooting

### Common Issues

#### 1. SFTP Connection Failed
```
Error: Connection timeout to SFTP server
```
**Solution**:
- Check firewall rules
- Verify SFTP host/port
- Test credentials manually

#### 2. Azure Upload Failed (401 Unauthorized)
```
Error: HTTP 401 - Authorization failed
```
**Solution**:
- Verify storage account key
- Check SAS token generation logic
- Ensure clock synchronization (SAS tokens are time-sensitive)

#### 3. Azure Upload Failed (403 Forbidden)
```
Error: HTTP 403 - Forbidden
```
**Solution**:
- Verify container exists
- Check SAS token permissions
- Ensure SAS token hasn't expired

#### 4. File Not Found in SFTP
```
Error: File not found in SFTP directory
```
**Solution**:
- Verify SFTP directory path
- Check file permissions
- Ensure working directory is set correctly

#### 5. Scheduler Not Triggering
```
Warning: Batch job not executing at scheduled time
```
**Solution**:
- Verify cron expression
- Check timezone configuration
- Review application startup logs

## Performance Tuning

### Batch Size Configuration

```properties
batch.size=10  # Process N files concurrently
```

### Connection Timeouts

```properties
# Increase for large files
http.connection.timeout=300000  # 5 minutes
```

### File Size Limits

```properties
file.max.size.mb=100
```

### Worker Configuration (CloudHub)

- **MICRO** (0.1 vCores): Up to 10 files/minute
- **SMALL** (0.2 vCores): Up to 25 files/minute
- **MEDIUM** (1 vCore): Up to 100 files/minute

## Maintenance

### Regular Tasks

1. **Monitor SFTP directories**:
   - Archive cleanup (monthly)
   - Error directory review (weekly)

2. **Azure Storage**:
   - Review blob lifecycle policies
   - Monitor storage costs

3. **Log Rotation**:
   - Configured automatically (10 MB per file, max 10 files)

4. **Credential Rotation**:
   - SFTP passwords (quarterly)
   - Azure storage keys (quarterly)

## Support

### Documentation
- MuleSoft Documentation: https://docs.mulesoft.com
- Azure Blob Storage API: https://docs.microsoft.com/azure/storage/blobs/

### Contact
- Email: support@example.com
- Slack: #mulesoft-integrations

## License

Copyright (c) 2025 Example Corporation. All rights reserved.

## Version History

### 1.0.0 (2025-11-11)
- Initial production release
- Daily scheduled batch processing
- SFTP to Azure Blob Storage integration
- Dynamic SAS token generation
- Comprehensive error handling and logging
- Support for multiple environments (dev, qa, prod)
