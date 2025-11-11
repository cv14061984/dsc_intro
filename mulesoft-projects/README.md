# MDM to ERS Real Estate Integration - MuleSoft Project

## Overview

This repository contains production-ready MuleSoft applications for integrating real estate data from **MDM (Master Data Management)** to **ERS (SAP HANA DB)** system.

### Business Context
- **Source System**: MDM
- **Destination System**: ERS (SAP HANA DB)
- **Business Criticality**: Financial
- **Service Tier**: Maintenance
- **Data Domain**: Real Estate Properties

## Architecture

This integration follows the **API-Led Connectivity** approach with three layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    EXPERIENCE LAYER                         │
│  ┌───────────────────────────────────────────────────┐     │
│  │   exp-mdm-realestate-gf-api                       │     │
│  │   - Exposes MDM Real Estate Data                  │     │
│  │   - Port: 8081                                    │     │
│  └───────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                     PROCESS LAYER                           │
│  ┌───────────────────────────────────────────────────┐     │
│  │   proc-magma-companyfile-gf-api                   │     │
│  │   - Orchestrates data processing                  │     │
│  │   - Batch processing & transformation             │     │
│  │   - Port: 8082                                    │     │
│  └───────────────────────────────────────────────────┘     │
└─────────────────────────────────────────────────────────────┘
                           │
           ┌───────────────┴───────────────┐
           ▼                               ▼
┌──────────────────────────┐   ┌──────────────────────────┐
│     SYSTEM LAYER         │   │     SYSTEM LAYER         │
│  ┌────────────────────┐  │   │  ┌────────────────────┐  │
│  │ sys-magma-grmdm-   │  │   │  │ sys-ers-realestate-│  │
│  │ gf-api             │  │   │  │ gf-api             │  │
│  │ - GRMDM System API │  │   │  │ - ERS System API   │  │
│  │ - Port: 8083       │  │   │  │ - SAP HANA DB      │  │
│  └────────────────────┘  │   │  │ - Port: 8084       │  │
│                          │   │  └────────────────────┘  │
└──────────────────────────┘   └──────────────────────────┘
           │                               │
           ▼                               ▼
    [GRMDM Database]              [SAP HANA - ERS]
```

## Project Structure

```
mulesoft-projects/
├── exp-mdm-realestate-gf-api/          # Experience API (Source)
│   ├── pom.xml
│   ├── mule-artifact.json
│   └── src/
│       ├── main/
│       │   ├── mule/                   # Mule flows
│       │   └── resources/
│       │       ├── api/                # RAML specifications
│       │       ├── properties/         # Environment configs
│       │       ├── dwl/                # DataWeave scripts
│       │       └── schemas/            # JSON/XML schemas
│       └── test/                       # MUnit tests
│
├── proc-magma-companyfile-gf-api/      # Process API (Orchestration)
│   ├── pom.xml
│   ├── mule-artifact.json
│   └── src/
│       ├── main/
│       │   ├── mule/
│       │   └── resources/
│       │       ├── api/
│       │       └── properties/
│       └── test/
│
├── sys-magma-grmdm-gf-api/             # System API (GRMDM)
│   ├── pom.xml
│   ├── mule-artifact.json
│   └── src/
│       ├── main/
│       │   ├── mule/
│       │   └── resources/
│       │       ├── api/
│       │       └── properties/
│       └── test/
│
├── sys-ers-realestate-gf-api/          # System API (ERS Destination)
│   ├── pom.xml
│   ├── mule-artifact.json
│   └── src/
│       ├── main/
│       │   ├── mule/
│       │   └── resources/
│       │       ├── api/
│       │       └── properties/
│       └── test/
│
└── shared-config/                       # Shared configurations
    ├── properties/                      # Common properties
    ├── dwl/                            # Reusable DataWeave modules
    ├── schemas/                        # Shared schemas
    └── policies/                       # API policies
```

## APIs Overview

### 1. exp-mdm-realestate-gf-api (Experience API)
**Purpose**: Expose MDM Real Estate data through a RESTful API

**Port**: 8081
**Base Path**: `/api/mdm/realestate/v1`

**Endpoints**:
- `GET /properties` - Retrieve real estate properties with filtering
- `GET /properties/{propertyId}` - Get specific property by ID
- `GET /health` - Health check

**Key Features**:
- Oracle database connection to MDM
- Advanced filtering (property type, status, date range)
- Pagination support
- Comprehensive error handling
- Security with client credentials

---

### 2. proc-magma-companyfile-gf-api (Process API)
**Purpose**: Orchestrate data processing and transformation between MDM and ERS

**Port**: 8082
**Base Path**: `/api/proc/magma/companyfile/v1`

**Endpoints**:
- `POST /process` - Initiate batch processing
- `GET /process/{processId}/status` - Check processing status
- `GET /health` - Health check

**Key Features**:
- Batch processing with MuleSoft Batch module
- Asynchronous processing support
- Integration with both MDM and ERS APIs
- Retry logic and error handling
- Processing status tracking

---

### 3. sys-magma-grmdm-gf-api (System API)
**Purpose**: System API for MAGMA GRMDM data operations

**Port**: 8083
**Base Path**: `/sys/magma/grmdm/v1`

**Endpoints**:
- `GET /companies` - Retrieve company data from GRMDM
- `GET /health` - Health check

**Key Features**:
- Direct database access to GRMDM
- Company data retrieval
- Optimized queries

---

### 4. sys-ers-realestate-gf-api (System API - Destination)
**Purpose**: System API for ERS (SAP HANA DB) real estate operations

**Port**: 8084
**Base Path**: `/sys/ers/realestate/v1`

**Endpoints**:
- `POST /properties` - Create/Update property in ERS
- `GET /properties` - Retrieve properties from ERS
- `GET /properties/{propertyId}` - Get specific property
- `PUT /properties/{propertyId}` - Update property
- `DELETE /properties/{propertyId}` - Delete property
- `GET /health` - Health check with DB connectivity status

**Key Features**:
- SAP HANA database integration
- Upsert operations (insert or update)
- CRUD operations for real estate data
- Connection pooling
- Database health monitoring

---

## Technology Stack

- **MuleSoft Runtime**: 4.6.0
- **Java**: 8+
- **Maven**: 3.8+
- **Databases**:
  - Oracle (MDM, GRMDM)
  - SAP HANA (ERS)
- **API Specification**: RAML 1.0
- **Transformation**: DataWeave 2.0

## Prerequisites

1. **Anypoint Studio** 7.14+ (for development)
2. **Java Development Kit** 8 or 11
3. **Maven** 3.8+
4. **MuleSoft Runtime** 4.6.0
5. **Database Access**:
   - Oracle JDBC Driver (included in pom.xml)
   - SAP HANA NGDBC Driver (included in pom.xml)
6. **Anypoint Platform Account** (for deployment)

## Environment Configuration

Each API supports multiple environments: **dev**, **test**, and **prod**.

### Setting Environment

```bash
# For local development
mvn clean install -Denv=dev

# For deployment
mvn clean deploy -Denv=prod
```

### Properties Files

Each API has environment-specific properties:
- `src/main/resources/properties/dev.properties`
- `src/main/resources/properties/test.properties`
- `src/main/resources/properties/prod.properties`

### Secure Properties

Sensitive data (passwords, secrets) should be encrypted using MuleSoft Secure Properties:

```bash
# Encrypt a property value
java -cp mule-secure-configuration-property-module-<version>.jar \
  com.mulesoft.modules.secure.tools.SecurePropertiesTool \
  string encrypt Blowfish CBC <encryption-key> <value-to-encrypt>
```

## Building the Projects

### Build Individual API

```bash
cd mulesoft-projects/exp-mdm-realestate-gf-api
mvn clean package
```

### Build All APIs

```bash
cd mulesoft-projects
for dir in exp-mdm-realestate-gf-api proc-magma-companyfile-gf-api sys-magma-grmdm-gf-api sys-ers-realestate-gf-api; do
  cd $dir
  mvn clean package -Denv=prod
  cd ..
done
```

## Running Locally

### Using Anypoint Studio
1. Import project as Maven project
2. Configure environment variable: `env=dev`
3. Run the application
4. Access API Console at: `http://localhost:808x/console` (where x is the port number)

### Using Command Line

```bash
cd mulesoft-projects/exp-mdm-realestate-gf-api
mvn mule:run -Denv=dev
```

## Testing

### Run Unit Tests (MUnit)

```bash
mvn clean test
```

### Run with Coverage Report

```bash
mvn clean test munit:coverage-report
```

Coverage reports will be generated in `target/site/munit/coverage/`

### Manual Testing

Use the API Console or tools like Postman:

```bash
# Health check
curl http://localhost:8081/api/mdm/realestate/v1/health

# Get properties (with authentication)
curl -H "client_id: your_client_id" \
     -H "client_secret: your_client_secret" \
     http://localhost:8081/api/mdm/realestate/v1/properties
```

## Deployment

### Deploy to CloudHub

```bash
mvn clean deploy -DmuleDeploy \
  -Denv=prod \
  -Danypoint.username=<username> \
  -Danypoint.password=<password> \
  -Danypoint.environment=Production \
  -Danypoint.workers=1 \
  -Danypoint.workerType=MICRO
```

### Deploy to On-Premise Runtime

1. Build the deployable archive:
   ```bash
   mvn clean package -Denv=prod
   ```

2. Deploy the JAR file from `target/` to your Mule runtime:
   ```bash
   cp target/exp-mdm-realestate-gf-api-1.0.0-mule-application.jar \
      $MULE_HOME/apps/
   ```

## Monitoring and Logging

### Log Configuration

Logs are configured for JSON format in production:
- `log.json.enabled=true`
- `log.level=INFO` (prod)
- `log.level=DEBUG` (dev)

### Key Monitoring Points

1. **Correlation ID Tracking**: Each request has a unique correlation ID for tracing
2. **Error Notifications**: Configured email notifications for errors
3. **Health Endpoints**: Monitor application and database connectivity
4. **Performance Metrics**: Database connection pool monitoring

### CloudHub Monitoring

If deployed to CloudHub, use Anypoint Monitoring for:
- Application metrics
- API analytics
- Custom dashboards
- Alerts and notifications

## Security Considerations

1. **Authentication**: Client ID/Secret based authentication
2. **Encryption**: Secure properties for sensitive data
3. **TLS**: HTTPS for all API communications
4. **Rate Limiting**: Configured per environment
5. **Input Validation**: Comprehensive validation on all inputs
6. **SQL Injection Prevention**: Parameterized queries
7. **Error Handling**: No sensitive data in error responses

## Performance Optimization

1. **Database Connection Pooling**: Configured with min/max pool sizes
2. **Batch Processing**: For bulk operations
3. **Async Processing**: For long-running tasks
4. **Caching**: Consider implementing for frequently accessed data
5. **Pagination**: Implemented for large result sets

## Troubleshooting

### Common Issues

#### Database Connection Failures
```
Error: DB:CONNECTIVITY
Solution:
- Verify database host/port/credentials in properties files
- Check network connectivity
- Verify JDBC driver is included in pom.xml
```

#### API Authentication Errors
```
Error: UNAUTHORIZED
Solution:
- Verify client_id and client_secret headers
- Check API Manager policies
- Validate credentials in properties files
```

#### Timeout Issues
```
Error: HTTP:TIMEOUT
Solution:
- Increase timeout values in properties
- Check downstream service performance
- Review database query performance
```

## Development Guidelines

1. **Code Style**: Follow MuleSoft best practices
2. **Naming Conventions**: Use descriptive names for flows and variables
3. **Error Handling**: Always implement proper error handling
4. **Logging**: Use correlation IDs and appropriate log levels
5. **DataWeave**: Reuse common transformations from shared-config
6. **Testing**: Maintain minimum 75% code coverage
7. **Documentation**: Keep RAML specifications up to date

## CI/CD Pipeline

Recommended Jenkins/GitLab CI pipeline:

```yaml
stages:
  - build
  - test
  - deploy-dev
  - deploy-test
  - deploy-prod

build:
  script:
    - mvn clean package -Denv=dev

test:
  script:
    - mvn clean test
    - mvn munit:coverage-report

deploy-prod:
  script:
    - mvn clean deploy -DmuleDeploy -Denv=prod
  only:
    - main
```

## Support and Maintenance

### Contact Information
- **Development Team**: dev-team@organization.com
- **Production Support**: prod-support@organization.com

### Service Level Agreement
- **Business Criticality**: Financial
- **Service Tier**: Maintenance
- **Response Time**: Based on organizational SLA

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2025-01-15 | Initial production release |

## License

Proprietary - Organization Internal Use Only

---

**Last Updated**: 2025-01-15
**Maintained By**: MuleSoft Integration Team
