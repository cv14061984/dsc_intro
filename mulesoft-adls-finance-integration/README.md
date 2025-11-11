# MuleSoft ADLS Finance Integration

Production-ready MuleSoft integration for syncing company file data from MDM to Azure Data Lake Storage (ADLS).

## Overview

This integration implements a scheduled data synchronization pipeline that:
- Fetches company file data from MDM system via scheduler API
- Transforms and processes the data through multiple API layers
- Writes the processed data to Azure Data Lake Storage for finance records
- Runs on a scheduled basis (Daily twice at 7 AM IST)

## Architecture

The solution follows the **API-Led Connectivity** approach with three layers:

### 1. Experience Layer: `exp-simp-companyfile-gf-api`
- **Purpose**: Orchestration and scheduling
- **Endpoints**:
  - `GET /api/experience/company-file/sync` - Manual trigger
- **Features**:
  - Scheduler (Daily twice at 7 AM IST: `0 30 1/12 1/1 * ? *`)
  - Correlation ID generation
  - Process orchestration

### 2. Process Layer: `proc-magma-companyfile-gf-api`
- **Purpose**: Business logic and data transformation
- **Endpoints**:
  - `POST /api/process/company-file/sync` - Process orchestration
- **Features**:
  - Data fetching from MDM
  - Business transformation logic
  - Batch processing
  - ADLS writing coordination

### 3. System Layer
#### a. `sys-magma-grmdm-gf-api` (MDM System API)
- **Purpose**: MDM system abstraction
- **Endpoints**:
  - `GET /api/system/mdm/company-file` - Fetch company data
- **Features**:
  - Retry logic (max 3 retries)
  - Response transformation
  - Error handling

#### b. `sys-adls-financerecords-gf-app` (ADLS System API)
- **Purpose**: Azure Data Lake Storage abstraction
- **Endpoints**:
  - `POST /api/system/adls/write` - Write data to ADLS
  - `GET /api/system/adls/health` - Health check
- **Features**:
  - Blob creation and update
  - Automatic retry on failure
  - File naming with timestamps

## Technical Specifications

### Business Details
- **Business Criticality**: Financial
- **Service Tier**: Maintenance
- **Schedule**: Daily Twice at 7 AM IST (0 30 1/12 1/1 * ? *)
- **Source System**: MDM
- **Source API**: exp-magma-scheduler-api
- **Destination System**: Azure Data Lake Storage (ADLS)
- **Destination API**: sys-adls-financerecords-gf-app

### Configuration

#### Environment Variables
The application supports three environments: `dev`, `uat`, and `prod`

Set the environment using:
```bash
-Denv=dev
```

#### Properties Files
- `config-dev.yaml` - Development environment
- `config-uat.yaml` - UAT environment
- `config-prod.yaml` - Production environment
- `secure-properties-dev.yaml` - Encrypted credentials

### Key Dependencies
- Mule Runtime: 4.4.0
- HTTP Connector: 1.7.3
- Azure Storage Connector: 3.1.1
- Secure Configuration Property Module: 1.2.5
- API Kit: 1.8.2
- JSON Module: 2.3.1
- Validation Module: 2.0.3

## Prerequisites

1. **MuleSoft Runtime**
   - Mule Runtime 4.4.0 or higher
   - Anypoint Studio (for local development)

2. **Azure Access**
   - Azure Storage Account with Data Lake enabled
   - Account name and access key
   - Container created for finance records

3. **MDM Access**
   - MDM API endpoint URL
   - API credentials (Client ID and Secret)

4. **Maven**
   - Maven 3.6+ installed

## Setup Instructions

### 1. Clone the Repository
```bash
git clone <repository-url>
cd mulesoft-adls-finance-integration
```

### 2. Configure Secure Properties

Edit `src/main/resources/secure-properties-dev.yaml` and replace placeholders:

```yaml
adls:
  account:
    key: "<YOUR_ENCRYPTED_ADLS_ACCOUNT_KEY>"

mdm:
  api:
    clientId: "<YOUR_ENCRYPTED_CLIENT_ID>"
    clientSecret: "<YOUR_ENCRYPTED_CLIENT_SECRET>"

encryption:
  key: "<YOUR_ENCRYPTION_KEY>"
```

**To encrypt properties:**
```bash
# Use MuleSoft Secure Properties Tool
java -cp secure-properties-tool.jar com.mulesoft.tools.SecurePropertiesTool \
  string encrypt Blowfish CBC <your-encryption-key> <value-to-encrypt>
```

### 3. Update Environment Configuration

Edit `src/main/resources/config-dev.yaml` (or config-uat/prod.yaml) with your environment-specific values:

```yaml
mdm:
  host: "your-mdm-api.company.com"

adls:
  accountName: "youradlsaccount"
  containerName: "finance-records"
```

### 4. Build the Project

```bash
mvn clean package
```

### 5. Deploy

#### Option A: Deploy to CloudHub
```bash
mvn deploy -DmuleDeploy \
  -Denv=dev \
  -Dencryption.key=<your-encryption-key> \
  -Dmule.version=4.4.0 \
  -Dworkers=1 \
  -DworkerType=MICRO
```

#### Option B: Deploy to On-Premise Runtime
1. Copy the generated JAR from `target/mulesoft-adls-finance-integration-1.0.0-mule-application.jar`
2. Place in `$MULE_HOME/apps/` directory
3. Set environment variables:
   ```bash
   export env=dev
   export encryption.key=<your-encryption-key>
   ```

#### Option C: Run in Anypoint Studio
1. Import project into Anypoint Studio
2. Right-click project → Run As → Mule Application
3. Set Run Configuration VM arguments:
   ```
   -Denv=dev -Dencryption.key=<your-encryption-key>
   ```

## Testing

### Manual Trigger
Trigger the sync manually via HTTP:

```bash
curl -X GET http://localhost:8081/api/experience/company-file/sync
```

Expected Response:
```json
{
  "status": "SUCCESS",
  "message": "Company file sync completed successfully",
  "correlationId": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2025-11-11T10:30:00Z",
  "processingTime": "5432ms",
  "recordsProcessed": 150
}
```

### Health Check
Check ADLS system health:

```bash
curl -X GET http://localhost:8081/api/system/adls/health
```

Expected Response:
```json
{
  "status": "UP",
  "service": "sys-adls-financerecords-gf-app",
  "timestamp": "2025-11-11T10:30:00Z",
  "adls": {
    "accountName": "gffinancedevadls",
    "containerName": "finance-records",
    "connected": true
  }
}
```

### Scheduler Verification
The scheduler runs automatically based on the cron expression: `0 30 1/12 1/1 * ? *`

This translates to:
- **Daily twice at 7:00 AM IST** (1:30 AM UTC and 1:30 PM UTC)
- Timezone: Asia/Kolkata

To verify scheduler execution, check logs:
```bash
tail -f $MULE_HOME/logs/mulesoft-adls-finance-integration.log
```

## Monitoring and Logging

### Log Levels
- **Development**: INFO
- **UAT**: INFO
- **Production**: WARN

### Log File Location
```
$MULE_HOME/logs/mulesoft-adls-finance-integration.log
```

### Correlation ID
Every request is tagged with a correlation ID for end-to-end tracking:
```
[INFO] 2025-11-11 10:30:00 [scheduler-thread-1] [550e8400-e29b-41d4-a716-446655440000] com.gf.finance: [SCHEDULER] Starting company file sync
```

### Key Log Messages
- `[SCHEDULER]` - Scheduler-triggered events
- `[HTTP]` - HTTP-triggered events
- `[EXPERIENCE]` - Experience layer logs
- `[PROCESS]` - Process layer logs
- `[SYSTEM-MDM]` - MDM system API logs
- `[SYSTEM-ADLS]` - ADLS system API logs

## Error Handling

The application implements comprehensive error handling:

1. **HTTP Connectivity Errors** - Returns 503 with retry logic
2. **HTTP Timeout Errors** - Returns 504 with retry logic
3. **Validation Errors** - Returns 400 with validation details
4. **Transformation Errors** - Returns 500 with transformation details
5. **Azure Storage Errors** - Returns 500 with ADLS-specific errors

### Retry Configuration
- **MDM API**: Max 3 retries with 5-second delay
- **ADLS API**: Automatic retry via Azure Storage connector

### Error Notifications
Errors are logged and can be configured to send notifications to:
- Development: `dev-team@gf.com`
- UAT: `uat-team@gf.com`
- Production: `finance-ops@gf.com`

## Data Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Scheduler  │────▶│  Experience  │────▶│   Process   │
│  (Trigger)  │     │     Layer    │     │    Layer    │
└─────────────┘     └──────────────┘     └─────────────┘
                                                 │
                                                 ▼
                    ┌─────────────┐     ┌─────────────┐
                    │  MDM System │◀────│   Fetch     │
                    │     API     │     │    Data     │
                    └─────────────┘     └─────────────┘
                                                 │
                                                 ▼
                                        ┌─────────────┐
                                        │ Transform   │
                                        │    Data     │
                                        └─────────────┘
                                                 │
                                                 ▼
                    ┌─────────────┐     ┌─────────────┐
                    │    ADLS     │◀────│ ADLS System │
                    │  Storage    │     │     API     │
                    └─────────────┘     └─────────────┘
```

## Data Transformation

### MDM Source Format (Example)
```json
{
  "companies": [
    {
      "id": "C001",
      "name": "Example Corp",
      "code": "EXMP",
      "regNumber": "12345678",
      "taxId": "TAX-001"
    }
  ]
}
```

### ADLS Target Format (Example)
```json
{
  "metadata": {
    "sourceSystem": "MDM",
    "destinationSystem": "ADLS",
    "correlationId": "550e8400-e29b-41d4-a716-446655440000",
    "processedTimestamp": "2025-11-11T10:30:00Z",
    "recordCount": 1
  },
  "records": [
    {
      "companyId": "C001",
      "companyName": "Example Corp",
      "companyCode": "EXMP",
      "auditInfo": {
        "syncTimestamp": "2025-11-11T10:30:00Z",
        "correlationId": "550e8400-e29b-41d4-a716-446655440000",
        "sourceSystem": "MDM",
        "processedBy": "proc-magma-companyfile-gf-api"
      }
    }
  ]
}
```

## File Naming Convention

Files are written to ADLS with the following naming pattern:
```
companyfile_<timestamp>.json
```

Example: `companyfile_20251111_103000.json`

Location in ADLS:
```
Container: finance-records
Directory: company-files
Full Path: finance-records/company-files/companyfile_20251111_103000.json
```

## Performance Considerations

- **Batch Size**: 100 records (configurable via `business.batchSize`)
- **Connection Timeout**: 30 seconds (configurable via `mdm.timeout`)
- **Worker Type**: MICRO (1 vCore, 1.5 GB memory)
- **Expected Throughput**: ~100-500 records per execution

## Security

1. **Encrypted Properties**: All sensitive data (API keys, credentials) are encrypted using Blowfish algorithm
2. **HTTPS**: All external API calls use HTTPS
3. **Correlation ID**: End-to-end request tracking
4. **No Hardcoded Credentials**: All credentials externalized to properties files

## Troubleshooting

### Issue: Scheduler not triggering
**Solution**:
- Verify cron expression in `config-<env>.yaml`
- Check `scheduler.enabled` is set to `true`
- Verify timezone setting

### Issue: MDM connection timeout
**Solution**:
- Check MDM host and port in configuration
- Verify firewall rules allow outbound HTTPS
- Increase `mdm.timeout` value

### Issue: ADLS write failure
**Solution**:
- Verify ADLS account key is correct
- Check container and directory exist in ADLS
- Verify network connectivity to Azure
- Check Azure Storage account access permissions

### Issue: Transformation errors
**Solution**:
- Review MDM response format
- Check DataWeave transformations in `proc-magma-companyfile-gf-api.xml`
- Verify field mappings match source data

## Maintenance

### Updating Dependencies
```bash
# Update to latest patch version
mvn versions:use-latest-releases

# Rebuild
mvn clean package
```

### Changing Schedule
Edit `src/main/resources/config-<env>.yaml`:
```yaml
scheduler:
  cron: "0 30 1/12 1/1 * ? *"  # Modify this line
  timezone: "Asia/Kolkata"
```

### Adding New Fields
1. Update transformation in `proc-magma-companyfile-gf-api.xml` → `proc-transform-data-subflow`
2. Update MDM response mapping in `sys-magma-grmdm-gf-api.xml` → `sys-mdm-transform-response-subflow`
3. Test thoroughly in dev environment

## Support

For issues or questions:
- **Development Team**: dev-team@gf.com
- **UAT Team**: uat-team@gf.com
- **Finance Operations**: finance-ops@gf.com

## Version History

### v1.0.0 (Initial Release)
- Experience API with scheduler
- Process API with transformation
- MDM System API with retry logic
- ADLS System API with blob operations
- Comprehensive error handling
- Production-ready logging
- Environment-specific configurations

## License

Proprietary - GF Finance Division
