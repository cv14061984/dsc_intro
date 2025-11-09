# AWS S3 to SFTP Integration

## Overview

This is a production-ready MuleSoft application that automates the daily transfer of employee CSV files from AWS S3 to an SFTP server. The application processes up to 8 files, archives them with timestamps, and securely transfers them to the target system.

## Features

- **Scheduled Batch Processing**: Daily automated job using Mule Scheduler
- **AWS S3 Integration**: Reads CSV files from S3 input folder
- **File Archiving**: Maintains timestamped copies in S3 archive folder
- **SFTP Transfer**: Securely transfers files to target SFTP server
- **Error Handling**: Comprehensive error handling with retry mechanisms
- **Monitoring**: Health check endpoint for application monitoring
- **Audit Logging**: Detailed logging for compliance and troubleshooting
- **No Data Transformation**: Direct file transfer without modification

## Architecture

```
┌─────────────┐
│  Scheduler  │ (Daily at Midnight)
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────────┐
│     List Files from S3 Input Folder        │
│     (Filter *.csv, Max 8 files)            │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
       ┌───────────────────────┐
       │   For Each File       │
       └───────────┬───────────┘
                   │
                   ├── Read from S3
                   │
                   ├── Archive to S3 (with timestamp)
                   │
                   ├── Transfer to SFTP
                   │
                   └── Delete from S3 Input Folder
```

## Project Structure

```
aws-s3-sftp-integration/
├── pom.xml                                    # Maven project configuration
├── mule-artifact.json                         # Mule artifact descriptor
├── README.md                                  # This file
└── src/
    ├── main/
    │   ├── mule/
    │   │   ├── global-config.xml             # S3 and SFTP connector configs
    │   │   ├── s3-to-sftp-flow.xml           # Main integration flow
    │   │   └── error-handler.xml             # Error handling logic
    │   └── resources/
    │       ├── properties/
    │       │   ├── dev.properties            # Development environment config
    │       │   └── prod.properties           # Production environment config
    │       └── log4j2.xml                    # Logging configuration
    └── test/
        └── munit/                            # Unit tests directory
```

## Prerequisites

### Software Requirements
- **Mule Runtime**: 4.4.0 or higher
- **Java**: JDK 8 or 11
- **Maven**: 3.6.0 or higher
- **Anypoint Studio**: 7.12.0 or higher (for development)

### Access Requirements
- **AWS S3**:
  - Access Key and Secret Key
  - S3 bucket with appropriate IAM permissions
  - Bucket folders: `input/`, `archive/`, `error/`

- **SFTP Server**:
  - Host, Port, Username, Password
  - Write permissions to target folder

## Configuration

### Environment Properties

Configure the application by editing the properties files:

#### Development: `src/main/resources/properties/dev.properties`
#### Production: `src/main/resources/properties/prod.properties`

### Key Configuration Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `scheduler.frequency` | Batch job frequency in milliseconds | 86400000 (24 hours) |
| `s3.bucketName` | AWS S3 bucket name | employee-data-{env} |
| `s3.inputFolder` | Input folder in S3 | input |
| `s3.archiveFolder` | Archive folder in S3 | archive |
| `s3.maxFiles` | Maximum files to process per batch | 8 |
| `sftp.host` | SFTP server hostname | - |
| `sftp.port` | SFTP server port | 22 |
| `sftp.targetFolder` | Target folder on SFTP server | /Target |

### Secure Properties

For production, use MuleSoft's secure properties encryption:

1. Generate encryption key:
```bash
java -cp ~/.m2/repository/com/mulesoft/anypoint-cli-3.3.1.jar com.mulesoft.anypoint.client.cli.encryption.EncryptionKey
```

2. Encrypt sensitive values:
```bash
java -cp ~/.m2/repository/com/mulesoft/anypoint-cli-3.3.1.jar com.mulesoft.anypoint.client.cli.encryption.Encrypt --key <encryption-key> --value <secret-value>
```

3. Update `prod.properties` with encrypted values:
```properties
s3.accessKey=![encrypted-value]
s3.secretKey=![encrypted-value]
sftp.password=![encrypted-value]
```

## AWS S3 IAM Permissions

The AWS user/role requires the following IAM permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket",
        "s3:CopyObject"
      ],
      "Resource": [
        "arn:aws:s3:::employee-data-prod",
        "arn:aws:s3:::employee-data-prod/*"
      ]
    }
  ]
}
```

## Build and Deployment

### Build the Application

```bash
cd aws-s3-sftp-integration
mvn clean package
```

This generates: `target/aws-s3-sftp-integration-1.0.0.jar`

### Local Deployment (Development)

1. Set environment variable:
```bash
export env=dev
```

2. Run with Mule standalone:
```bash
$MULE_HOME/bin/mule -M-Denv=dev -app target/aws-s3-sftp-integration-1.0.0.jar
```

### CloudHub Deployment

```bash
mvn deploy -DmuleDeploy \
  -Dmule.version=4.4.0 \
  -Danypoint.username=<your-username> \
  -Danypoint.password=<your-password> \
  -Denvironment=Production \
  -Dworkers=1 \
  -DworkerType=MICRO \
  -Dregion=us-east-1 \
  -DobjectStoreV2=true
```

### On-Premises Deployment

1. Copy the JAR to Mule apps directory:
```bash
cp target/aws-s3-sftp-integration-1.0.0.jar $MULE_HOME/apps/
```

2. Configure runtime properties in `wrapper.conf`:
```
wrapper.java.additional.<n>=-Denv=prod
wrapper.java.additional.<n>=-Dmule.env=prod
```

3. Start Mule Runtime:
```bash
$MULE_HOME/bin/mule start
```

## Running and Monitoring

### Health Check

Test the application health:
```bash
curl http://localhost:8081/health
```

Expected response:
```json
{
  "status": "UP",
  "application": "aws-s3-sftp-integration",
  "environment": "prod",
  "timestamp": "2025-01-15T10:30:00",
  "version": "1.0.0"
}
```

### Manual Trigger (Testing)

To trigger the batch job manually (instead of waiting for scheduler):

1. Open Anypoint Studio
2. Right-click on the flow: `s3-to-sftp-batch-job`
3. Select "Run flow"

Or use REST API if you add a manual trigger endpoint.

### Monitoring Logs

Application logs location:
- **Standalone**: `$MULE_HOME/logs/`
- **CloudHub**: CloudHub Console → Logs

Log files:
- `aws-s3-sftp-integration.log` - Application logs
- `aws-s3-sftp-integration-error.log` - Error logs only
- `aws-s3-sftp-integration-audit.log` - Audit trail

### Key Metrics to Monitor

- Number of files processed per batch
- Error count per batch
- Processing duration
- S3 connectivity status
- SFTP connectivity status

## Error Handling

The application includes comprehensive error handling:

### Error Types Handled

1. **S3 Connectivity Errors**: Automatic retry with exponential backoff
2. **S3 Access Denied**: Logged for IAM permission review
3. **SFTP Connectivity Errors**: Retry with configurable attempts
4. **SFTP Authentication Errors**: Immediate failure with notification
5. **File Processing Errors**: File moved to error folder, batch continues

### Failed File Handling

Files that fail processing are:
1. Logged with error details
2. Copied to S3 `error/` folder with timestamp
3. Left in original location for retry
4. Counted in error metrics

## Troubleshooting

### Common Issues

#### 1. S3 Connection Failed
**Symptom**: `S3:CONNECTIVITY` error in logs

**Solutions**:
- Verify AWS credentials in properties file
- Check network connectivity to AWS
- Validate S3 bucket name and region
- Review IAM permissions

#### 2. SFTP Connection Failed
**Symptom**: `SFTP:CONNECTIVITY` error in logs

**Solutions**:
- Test SFTP connectivity: `sftp username@hostname`
- Verify firewall rules allow outbound port 22
- Check SFTP server availability
- Validate SFTP credentials

#### 3. Files Not Processing
**Symptom**: Batch job runs but processes 0 files

**Solutions**:
- Verify files exist in S3 input folder
- Check file extension is `.csv`
- Confirm S3 bucket and folder names
- Review S3 ListObjects permissions

#### 4. Scheduler Not Running
**Symptom**: No log entries after deployment

**Solutions**:
- Verify scheduler frequency configuration
- Check application deployment status
- Review Mule runtime logs for startup errors
- Confirm time zone settings

## Performance Tuning

### Recommendations

1. **Worker Size**: Scale based on file sizes and volume
2. **Connection Pooling**: Already configured for S3 and SFTP
3. **Batch Size**: Adjust `s3.maxFiles` based on requirements
4. **Timeout Values**: Increase for large files or slow networks
5. **Logging Level**: Use INFO in production, DEBUG for troubleshooting

### Expected Performance

- **File Size**: Up to 50 MB per CSV file
- **Processing Time**: ~5-10 seconds per file
- **Batch Duration**: ~1-2 minutes for 8 files
- **Throughput**: ~480 files per day (8 files × 60 batches)

## Security Best Practices

1. **Encrypt Credentials**: Use Mule secure properties
2. **Use IAM Roles**: Instead of access keys (CloudHub/EC2)
3. **Enable S3 Encryption**: Server-side encryption configured
4. **Restrict Network Access**: Firewall rules and security groups
5. **Regular Credential Rotation**: Rotate AWS and SFTP credentials
6. **Audit Logging**: Maintain logs for compliance
7. **TLS for SFTP**: Ensure encrypted transfer

## Maintenance

### Regular Tasks

- **Weekly**: Review error logs and failed files
- **Monthly**: Analyze performance metrics
- **Quarterly**: Credential rotation
- **Yearly**: Dependency updates and security patches

### Backup and Recovery

1. **S3 Archive**: Versioning enabled on archive folder
2. **Application Backups**: Store JAR files and configurations
3. **Disaster Recovery**: Document recovery procedures

## Testing

### Unit Testing with MUnit

Create MUnit tests in `src/test/munit/`:

```bash
mvn clean test
```

### Integration Testing

1. Create test CSV files in S3 input folder
2. Monitor processing in logs
3. Verify files appear in SFTP target folder
4. Confirm archive copies in S3
5. Check source files deleted from input folder

## Support and Contact

For issues or questions:

- **Development Team**: dev-team@example.com
- **Operations Team**: ops-team@example.com
- **Documentation**: [Project Wiki](#)

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-01-15 | Initial production release |

## License

Proprietary - Internal Use Only

---

**Last Updated**: January 15, 2025
**Maintained By**: MuleSoft Integration Team
