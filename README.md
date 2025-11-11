# IMS-Collibra User Status Integration

## Overview

This MuleSoft application synchronizes user status from Shell's Identity Management System (IMS) to Collibra Data Intelligence Cloud. The integration specifically handles users who are leaving the organization by automatically disabling their Collibra accounts.

## Business Context

When employees leave Shell, their status is updated in the IMS system with a "Leaver" event. This integration ensures that Collibra user accounts are automatically disabled to maintain security and compliance.

## Architecture

### Integration Flow

1. **Scheduler** - Triggers weekly (configurable)
2. **IMS SCIM API** - Retrieves users with `lastEvent = "Leaver"`
3. **Collibra GET API** - Fetches user details by email address
4. **Collibra PATCH API** - Updates user status (`enabled: false`)

### Design Principles

- **Synchronous Processing** - Real-time status updates
- **Batch Processing** - Efficient handling of multiple users
- **Error Handling** - Comprehensive error handling with retry logic
- **Audit Logging** - Complete audit trail for compliance
- **OAuth2 Authentication** - Secure API access

## Technical Specifications

### APIs Used

| System | Endpoint | Method | Purpose |
|--------|----------|--------|---------|
| IMS SCIM | `/corp-scim-office-api/v1/api/scim/search` | POST | Get leaver users |
| Collibra | `/rest/2.0/users` | GET | Get user by email |
| Collibra | `/rest/2.0/users/{userId}` | PATCH | Update user status |

### Field Mapping

| IMS Field | Collibra Field | Description |
|-----------|----------------|-------------|
| userName | emailAddress | User email (unique identifier) |
| lastEvent | - | Filter value: "Leaver" |
| statusChangeDate | - | When status changed |
| identityStatus | enabled | false for leavers |

## Project Structure

```
ims-collibra-integration/
├── src/
│   ├── main/
│   │   ├── mule/
│   │   │   ├── ims-collibra-integration.xml    # Main integration flow
│   │   │   ├── global-config.xml               # HTTP/OAuth configurations
│   │   │   └── error-handlers.xml              # Error handling logic
│   │   └── resources/
│   │       ├── properties/
│   │       │   ├── dev.properties              # Development environment
│   │       │   ├── test.properties             # Test environment
│   │       │   └── prod.properties             # Production environment
│   │       └── log4j2.xml                      # Logging configuration
│   └── test/
│       └── munit/                               # Unit tests
├── pom.xml                                      # Maven configuration
├── mule-artifact.json                           # Mule artifact descriptor
└── README.md                                    # This file
```

## Prerequisites

### Required Software

- **Anypoint Studio** 7.x or higher
- **Mule Runtime** 4.7.0 or higher (Enterprise Edition)
- **Java JDK** 1.8 or higher
- **Maven** 3.6.x or higher

### Required Credentials

1. **IMS OAuth2 Credentials**
   - Client ID
   - Client Secret
   - Token URL

2. **Collibra OAuth2 Credentials**
   - Client ID
   - Client Secret
   - Token URL

## Configuration

### Environment Properties

Update the appropriate properties file (`dev.properties`, `test.properties`, or `prod.properties`):

```properties
# IMS SCIM API
ims.oauth.clientId=YOUR_CLIENT_ID
ims.oauth.clientSecret=YOUR_CLIENT_SECRET

# Collibra API
collibra.oauth.clientId=YOUR_CLIENT_ID
collibra.oauth.clientSecret=YOUR_CLIENT_SECRET

# Scheduler (default: weekly = 604800000ms)
scheduler.frequency=604800000
```

### Secure Properties

For production deployments, use MuleSoft's Secure Properties module:

```bash
# Encrypt sensitive properties
mvn clean install -Dsecure.key=YourSecureKey
```

## Build & Deployment

### Local Development

1. **Import Project** into Anypoint Studio
   ```bash
   File > Import > Anypoint Studio > Packaged mule application (.jar)
   ```

2. **Configure Runtime**
   - Right-click project > Run As > Mule Application
   - Set VM argument: `-Dmule.env=dev`

3. **Test Locally**
   ```bash
   mvn clean test
   ```

### Build Package

```bash
# Development
mvn clean package -Pdev

# Test
mvn clean package -Ptest

# Production
mvn clean package -Pprod
```

### Deploy to CloudHub

```bash
mvn clean deploy -DmuleDeploy \
  -Dmule.env=prod \
  -Danypoint.username=YOUR_USERNAME \
  -Danypoint.password=YOUR_PASSWORD \
  -Dcloudhub.environment=Production \
  -Dcloudhub.workerType=MICRO \
  -Dcloudhub.workers=1 \
  -Dcloudhub.region=us-east-1
```

### Deploy to On-Premise Runtime

```bash
# Copy the JAR to Mule apps directory
cp target/ims-collibra-integration-1.0.0-mule-application.jar \
   $MULE_HOME/apps/
```

## Monitoring & Operations

### Logging

Logs are written to:
- **Console**: Standard output
- **File**: `$MULE_HOME/logs/ims-collibra-integration.log`

Log levels can be configured in `log4j2.xml` or via properties:
```properties
log.level=INFO  # DEBUG, INFO, WARN, ERROR
```

### Key Metrics

Monitor these key indicators:

- **Processed Users**: Total users processed per run
- **Success Rate**: Percentage of successful updates
- **Failure Rate**: Percentage of failed updates
- **Execution Time**: Time taken per batch

### Correlation IDs

Each execution generates a unique correlation ID for tracking:
```
X-Correlation-Id: <uuid>
```

Use this ID to trace requests across all systems.

### Health Checks

Monitor the following:

1. **Scheduler Status** - Verify weekly execution
2. **IMS API Connectivity** - Check OAuth token refresh
3. **Collibra API Connectivity** - Check OAuth token refresh
4. **Error Rates** - Alert on high failure rates

## Error Handling

### Error Types

| Error Type | Description | Action |
|------------|-------------|--------|
| CONNECTIVITY_ERROR | Network/connection issues | Retry with backoff |
| TIMEOUT_ERROR | Request timeout | Retry with backoff |
| CLIENT_ERROR (4xx) | Authentication/authorization | Check credentials |
| SERVER_ERROR (5xx) | API server issues | Retry with backoff |
| USER_NOT_FOUND | User doesn't exist in Collibra | Log warning, continue |
| TRANSFORMATION_ERROR | Data mapping issues | Fix mapping logic |

### Retry Strategy

- **IMS SCIM API**: 3 retries with exponential backoff
- **Collibra API**: 3 retries with exponential backoff
- **Failed Records**: Logged for manual review

## Testing

### Unit Tests

```bash
mvn clean test
```

### Coverage Report

```bash
mvn clean test munit:coverage-report
```

View coverage at: `target/site/munit/coverage/index.html`

### Manual Testing

1. **Verify Scheduler**
   - Check logs for scheduled execution
   - Verify weekly frequency

2. **Test IMS API**
   - Verify OAuth token acquisition
   - Verify leaver users retrieval

3. **Test Collibra API**
   - Verify user lookup by email
   - Verify user status update

## Security Considerations

### Authentication

- **OAuth2 Client Credentials** for both IMS and Collibra
- **Token Refresh** handled automatically
- **Credentials** stored securely (encrypted properties)

### Data Privacy

- **PII Handling**: Email addresses are processed
- **Audit Trail**: All updates are logged
- **Retention**: Logs retained per company policy

### Network Security

- **HTTPS Only**: All API calls use TLS
- **Firewall Rules**: Configure to allow outbound HTTPS
- **IP Whitelisting**: Configure as required

## Troubleshooting

### Common Issues

1. **Scheduler Not Running**
   - Check Mule app deployment status
   - Verify scheduler configuration
   - Check system logs

2. **Authentication Failures**
   - Verify OAuth credentials
   - Check token URL accessibility
   - Verify client permissions

3. **No Users Found**
   - Verify SCIM filter criteria
   - Check IMS user data
   - Validate search parameters

4. **User Not Found in Collibra**
   - Verify email address format
   - Check Collibra user exists
   - Validate email mapping

## Maintenance

### Scheduled Maintenance

- **Weekly**: Review error logs
- **Monthly**: Analyze success/failure metrics
- **Quarterly**: Review and update credentials

### Updates

- **Mule Runtime**: Follow MuleSoft upgrade path
- **Dependencies**: Regular security updates
- **API Changes**: Monitor IMS/Collibra API versions

## Support

### Contact Information

- **Integration Team**: integration-support@shell.com
- **MuleSoft Platform**: platform-team@shell.com
- **IMS Support**: ims-support@shell.com
- **Collibra Support**: collibra-support@shell.com

### Documentation

- [MuleSoft Documentation](https://docs.mulesoft.com)
- [Shell IMS SCIM API Guide](internal-link)
- [Collibra REST API Guide](https://developer.collibra.com)

## Change Log

### Version 1.0.0 (Initial Release)
- Weekly scheduler implementation
- IMS SCIM API integration
- Collibra user status update
- OAuth2 authentication
- Comprehensive error handling
- Audit logging

## License

Copyright (c) 2024 Shell Global Solutions International B.V.
Internal Use Only - Confidential

---

**Last Updated**: November 2024
**Version**: 1.0.0
**Maintained By**: Shell Integration Team
