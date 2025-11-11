# MuleSoft Company File Integration

## Overview

This project implements a production-ready API-led connectivity solution for retrieving Company File (Legal Entity) data from Informatica MDM (MAGMA) for the SIM-P source system.

## Architecture

The solution follows MuleSoft's API-led connectivity architecture with three layers:

```
┌─────────────┐
│   SIM-P     │ (Source System)
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Experience API                     │
│  exp-simp-companyfile-gf-api       │
│  Port: 8081 (dev) / 8443 (prod)    │
│  - Client-facing API                │
│  - Authentication & Authorization   │
│  - Rate limiting                    │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Process API                        │
│  proc-magma-companyfile-gf-api     │
│  Port: 8082 (dev) / 8443 (prod)    │
│  - Orchestration logic              │
│  - Data transformation              │
│  - Business rule application        │
│  - Data enrichment                  │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  System API                         │
│  sys-magma-grmdm-gf-api            │
│  Port: 8083 (dev) / 8443 (prod)    │
│  - MDM integration                  │
│  - Database/HTTP connectivity       │
│  - Data retrieval                   │
│  - APPROVED records only filter     │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Informatica MDM (MAGMA)            │
│  Company File Master Data           │
└─────────────────────────────────────┘
```

## Business Context

### Source System
- **Name**: SIM-P
- **Integration Type**: Adhoc/On-demand
- **Protocol**: HTTPS REST API

### Destination System
- **Name**: Informatica MDM (MAGMA)
- **Data Domain**: Company File (Legal Entities)
- **Connection**: Database (Oracle) or REST API

### Business Criticality
- **Level**: Financial
- **Service Tier**: Maintenance
- **SLA**: Standard production support

### Key Requirements
1. Only **APPROVED** legal entity records are exposed
2. Records in PENDING or REJECTED state are filtered out
3. Adhoc/on-demand retrieval (no scheduled batch processing)
4. Production-ready with comprehensive error handling and logging

## Project Structure

```
mulesoft-companyfile-integration/
│
├── exp-simp-companyfile-gf-api/          # Experience API
│   ├── src/main/
│   │   ├── mule/
│   │   │   ├── flows/                    # API implementation flows
│   │   │   ├── global-configs/           # Global configurations
│   │   │   └── error-handling/           # Error handlers
│   │   └── resources/
│   │       ├── api/                      # RAML specifications
│   │       ├── schemas/                  # Data type definitions
│   │       ├── examples/                 # Example requests/responses
│   │       └── properties/               # Environment configurations
│   ├── src/test/munit/                   # Unit tests
│   ├── pom.xml                           # Maven configuration
│   └── README.md                         # API-specific documentation
│
├── proc-magma-companyfile-gf-api/        # Process API
│   ├── src/main/
│   │   ├── mule/
│   │   │   ├── flows/                    # Orchestration flows
│   │   │   ├── global-configs/
│   │   │   └── error-handling/
│   │   └── resources/
│   │       ├── api/
│   │       ├── schemas/
│   │       ├── examples/
│   │       └── properties/
│   ├── src/test/munit/
│   ├── pom.xml
│   └── README.md
│
├── sys-magma-grmdm-gf-api/               # System API
│   ├── src/main/
│   │   ├── mule/
│   │   │   ├── flows/                    # MDM integration flows
│   │   │   ├── global-configs/
│   │   │   └── error-handling/
│   │   └── resources/
│   │       ├── api/
│   │       ├── schemas/
│   │       ├── examples/
│   │       └── properties/
│   ├── src/test/munit/
│   ├── pom.xml
│   └── README.md
│
└── README.md                             # This file
```

## APIs

### 1. Experience API (exp-simp-companyfile-gf-api)

**Purpose**: External-facing API for SIM-P to retrieve legal entity information

**Endpoints**:
- `GET /simp/companyfile/v1/legalentities` - Get legal entities (with filtering)
- `GET /simp/companyfile/v1/legalentities/{id}` - Get specific legal entity
- `GET /simp/companyfile/v1/health` - Health check

**Authentication**: Client ID & Secret (via headers)

**Key Features**:
- Input validation
- Authentication & authorization
- Rate limiting (via API Manager)
- Correlation ID tracking

### 2. Process API (proc-magma-companyfile-gf-api)

**Purpose**: Orchestration layer for business logic and data transformation

**Endpoints**:
- `GET /magma/companyfile/v1/legalentities` - Orchestrate legal entities retrieval
- `GET /magma/companyfile/v1/legalentities/{id}` - Orchestrate single entity retrieval
- `GET /magma/companyfile/v1/health` - Health check with dependency status

**Key Features**:
- Data transformation and enrichment
- Business rule application
- Calculated fields (isActive, daysUntilExpiry)
- Aggregation and filtering logic

### 3. System API (sys-magma-grmdm-gf-api)

**Purpose**: Direct integration with Informatica MDM

**Endpoints**:
- `GET /grmdm/companyfile/v1/legalentities` - Retrieve from MDM
- `GET /grmdm/companyfile/v1/legalentities/{id}` - Retrieve single entity from MDM
- `GET /grmdm/companyfile/v1/health` - Health check with MDM connectivity

**Integration Methods**:
- **Database**: Direct Oracle database queries (recommended for production)
- **HTTP**: REST API calls to MDM (alternative method)
- **Mock**: Mock data for development/testing

**Key Features**:
- APPROVED records filtering (enforced at system level)
- Database connection pooling
- Flexible integration method (DB or HTTP)
- SQL injection prevention

## Prerequisites

### Development Environment
- **Anypoint Studio**: 7.x or later
- **Java**: JDK 8 or later
- **Maven**: 3.6 or later
- **Mule Runtime**: 4.4.0

### Required Connectors
- HTTP Connector 1.7.3
- Database Connector 1.14.0
- Secure Properties Module 1.2.5
- APIKit Module 1.8.2

### External Dependencies
- **Informatica MDM**: Access credentials and connection details
- **Oracle JDBC Driver**: 19.8.0.0 (for database integration)
- **TLS Certificates**: Keystore and truststore for HTTPS

## Configuration

### Environment Properties

Each API has environment-specific property files:
- `dev.properties` - Development environment
- `test.properties` - Test environment
- `prod.properties` - Production environment
- `{env}-secure.properties` - Encrypted credentials

### Key Configuration Parameters

#### Experience API
```properties
http.listener.port=8081                    # API listener port
process.api.host=localhost                 # Process API host
process.api.port=8082                      # Process API port
```

#### Process API
```properties
http.listener.port=8082                    # API listener port
system.api.host=localhost                  # System API host
system.api.port=8083                       # System API port
```

#### System API
```properties
http.listener.port=8083                    # API listener port
mdm.integration.type=database              # Integration method: database|http|mock

# Database Configuration
mdm.db.host=mdm-db.company.com
mdm.db.port=1521
mdm.db.service.name=MDMPROD

# HTTP Configuration
mdm.api.host=mdm-api.company.com
mdm.api.port=443
```

### Secure Properties

Sensitive credentials are stored in encrypted property files:
```properties
# Database credentials
mdm.db.user=![encrypted_username]
mdm.db.password=![encrypted_password]

# API credentials
process.api.client.id=![encrypted_client_id]
process.api.client.secret=![encrypted_secret]

# TLS certificates
tls.keystore.password=![encrypted_password]
```

**Encryption**: Use MuleSoft Secure Properties module with Blowfish algorithm

## Build & Deploy

### Local Development

1. **Import Projects into Anypoint Studio**
   ```bash
   File → Import → Anypoint Studio Project from File System
   ```

2. **Configure Properties**
   - Update `dev.properties` with your environment details
   - Encrypt sensitive values in `dev-secure.properties`

3. **Run Applications**
   - Right-click project → Run As → Mule Application
   - Start in order: System API → Process API → Experience API

### Maven Build

```bash
# Build all projects
cd mulesoft-companyfile-integration

# Build Experience API
cd exp-simp-companyfile-gf-api
mvn clean install

# Build Process API
cd ../proc-magma-companyfile-gf-api
mvn clean install

# Build System API
cd ../sys-magma-grmdm-gf-api
mvn clean install
```

### CloudHub Deployment

```bash
# Deploy to CloudHub
mvn clean deploy -DmuleDeploy \
  -Dmule.env=prod \
  -Danypoint.username=your-username \
  -Danypoint.password=your-password
```

### Runtime Manager Deployment

1. Build deployment package:
   ```bash
   mvn clean package
   ```

2. Deploy via Runtime Manager:
   - Upload JAR from `target/` directory
   - Configure environment properties
   - Set worker size and count
   - Enable API Autodiscovery

## Testing

### Manual Testing

Use the built-in APIKit Console (available in development mode):
- Experience API: `https://localhost:8081/console`
- Process API: `https://localhost:8082/console`
- System API: `https://localhost:8083/console`

### Sample Requests

#### Get Legal Entities
```bash
curl -X GET "https://api.company.com/simp/companyfile/v1/legalentities?country=US&limit=10" \
  -H "client_id: your-client-id" \
  -H "client_secret: your-client-secret"
```

#### Get Specific Legal Entity
```bash
curl -X GET "https://api.company.com/simp/companyfile/v1/legalentities/LE001234" \
  -H "client_id: your-client-id" \
  -H "client_secret: your-client-secret"
```

### MUnit Tests

Run automated tests:
```bash
mvn test
```

Coverage reports are generated in `target/site/munit/coverage/`

## Error Handling

### Global Error Handler

All APIs implement comprehensive error handling:

| Error Type | HTTP Status | Description |
|------------|-------------|-------------|
| APIKIT:BAD_REQUEST | 400 | Invalid request parameters |
| APIKIT:NOT_FOUND | 404 | Resource not found |
| HTTP:TIMEOUT | 504 | Downstream service timeout |
| HTTP:CONNECTIVITY | 503 | Service unavailable |
| MDM:NOT_FOUND | 404 | Legal entity not found in MDM |
| ANY | 500 | Unexpected error |

### Error Response Format

```json
{
  "status": "404",
  "error": "Not Found",
  "message": "Legal entity LE001234 not found or not approved",
  "timestamp": "2025-11-11T10:30:00Z",
  "correlationId": "550e8400-e29b-41d4-a716-446655440000"
}
```

## Logging

### Log Categories

- API Name: `${api.name}`
- Correlation ID: Included in all log messages
- Log Levels: INFO, WARN, ERROR, DEBUG

### Log Format

```
[INFO] Incoming Request - CorrelationId: 550e8400... - Path: /legalentities - Method: GET
[INFO] Successfully retrieved 10 legal entities - CorrelationId: 550e8400...
[ERROR] Timeout Error - CorrelationId: 550e8400... - Error: Connection timeout
```

### Monitoring

- **CloudWatch**: For CloudHub deployments
- **Splunk/ELK**: For on-premise deployments
- **Anypoint Monitoring**: Built-in monitoring and analytics

## Security

### Authentication & Authorization

1. **Client ID & Secret**: Required for all API calls
2. **TLS/HTTPS**: All communications encrypted
3. **API Manager Policies**:
   - Client ID Enforcement
   - Rate Limiting
   - IP Whitelisting (optional)
   - OAuth 2.0 (optional)

### Data Security

- Sensitive data encrypted at rest and in transit
- Secure properties for credentials
- Database connection pooling with credential rotation support
- No logging of sensitive data (PII, credentials)

## Performance Considerations

### System API (MDM Integration)

- **Database Connection Pool**: Min 5, Max 20 connections (prod)
- **Query Timeout**: 120 seconds
- **Response Timeout**: 180 seconds
- **Pagination**: Default limit 100, max 1000 records

### Process API

- **Response Timeout**: 90 seconds
- **Connection Pool**: Shared across flows
- **Caching**: Consider implementing for frequently accessed data

### Experience API

- **Response Timeout**: 60 seconds
- **Rate Limiting**: Configure via API Manager
- **Circuit Breaker**: Consider implementing for resilience

## Troubleshooting

### Common Issues

1. **Connection Timeout to MDM**
   - Check network connectivity
   - Verify firewall rules
   - Increase timeout values in properties

2. **No Records Returned**
   - Verify MDM has APPROVED records
   - Check filter criteria
   - Review MDM database/API connectivity

3. **Authentication Failures**
   - Verify client credentials
   - Check API Manager policy configuration
   - Ensure API Autodiscovery is configured

4. **Certificate Issues**
   - Verify keystore and truststore paths
   - Check certificate expiration
   - Ensure proper certificate chain

## Maintenance

### Regular Tasks

1. **Certificate Renewal**: Monitor and renew TLS certificates before expiration
2. **Credential Rotation**: Rotate database and API credentials quarterly
3. **Dependency Updates**: Keep connectors and runtime up to date
4. **Performance Monitoring**: Review API response times and throughput
5. **Log Review**: Regular review of error logs and alerts

### Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-11-11 | Initial production release |

## Support

### Contact Information

- **Development Team**: mulesoft-team@company.com
- **Operations Team**: mulesoft-ops@company.com
- **Business Owner**: finance-it@company.com

### Documentation

- [Anypoint Platform Documentation](https://docs.mulesoft.com)
- [API-led Connectivity](https://www.mulesoft.com/resources/api/api-led-connectivity)
- [MuleSoft Best Practices](https://docs.mulesoft.com/mule-runtime/latest/intro-programming-concepts)

## License

Proprietary - Company Internal Use Only

---

**Last Updated**: November 11, 2025
**Maintained By**: MuleSoft Integration Team
