# Deployment Guide - MuleSoft Company File Integration

## Overview

This guide provides step-by-step instructions for deploying the Company File Integration APIs to various environments.

## Pre-Deployment Checklist

### Infrastructure Requirements

- [ ] Anypoint Platform access with deployment permissions
- [ ] CloudHub or Runtime Fabric environment provisioned
- [ ] API Manager access for policy configuration
- [ ] Network connectivity to Informatica MDM
- [ ] TLS certificates (keystore and truststore)
- [ ] Database credentials (if using database integration)

### Configuration Requirements

- [ ] Environment-specific properties configured
- [ ] Secure properties encrypted
- [ ] API client credentials generated
- [ ] MDM connection details verified
- [ ] Load balancer/DNS configured (for production)

## Deployment Sequence

**IMPORTANT**: Deploy APIs in the following order to ensure proper connectivity:

1. System API (sys-magma-grmdm-gf-api)
2. Process API (proc-magma-companyfile-gf-api)
3. Experience API (exp-simp-companyfile-gf-api)

## Development Environment Deployment

### Prerequisites
- Anypoint Studio 7.x installed
- Java JDK 8+ installed
- Maven 3.6+ installed

### Steps

#### 1. Import Projects

```bash
# Clone repository
git clone <repository-url>
cd mulesoft-companyfile-integration

# Import into Anypoint Studio
File → Import → Anypoint Studio Project from File System
```

#### 2. Configure Development Properties

Update `src/main/resources/properties/dev.properties` for each API:

**System API (Port 8083)**:
```properties
mdm.integration.type=mock  # Use mock for local development
http.listener.port=8083
```

**Process API (Port 8082)**:
```properties
system.api.host=localhost
system.api.port=8083
http.listener.port=8082
```

**Experience API (Port 8081)**:
```properties
process.api.host=localhost
process.api.port=8082
http.listener.port=8081
```

#### 3. Start Applications

```bash
# Terminal 1 - System API
cd sys-magma-grmdm-gf-api
mvn clean install mule:run

# Terminal 2 - Process API
cd proc-magma-companyfile-gf-api
mvn clean install mule:run

# Terminal 3 - Experience API
cd exp-simp-companyfile-gf-api
mvn clean install mule:run
```

#### 4. Verify Deployment

```bash
# System API Health
curl http://localhost:8083/grmdm/companyfile/v1/health

# Process API Health
curl http://localhost:8082/magma/companyfile/v1/health

# Experience API Health (requires auth)
curl http://localhost:8081/simp/companyfile/v1/health \
  -H "client_id: test-client-id" \
  -H "client_secret: test-client-secret"
```

## Test Environment Deployment

### CloudHub Deployment

#### 1. Prepare for Deployment

```bash
# Build deployable artifacts
cd mulesoft-companyfile-integration

# System API
cd sys-magma-grmdm-gf-api
mvn clean package

# Process API
cd ../proc-magma-companyfile-gf-api
mvn clean package

# Experience API
cd ../exp-simp-companyfile-gf-api
mvn clean package
```

#### 2. Deploy via Anypoint Platform UI

**For Each API:**

1. Login to Anypoint Platform
2. Navigate to Runtime Manager
3. Click "Deploy Application"
4. Configure deployment:

```yaml
Application Name: sys-magma-grmdm-gf-api-test
Runtime Version: 4.4.0
Worker Size: 0.1 vCores (Micro)
Workers: 1
Region: us-east-1
```

5. Upload JAR file from `target/` directory
6. Configure properties:

```properties
mule.env=test
api.id=<api-id-from-api-manager>
secure.key=<encryption-key>
```

7. Configure secure properties in "Properties" tab
8. Enable "Object Store V2"
9. Click "Deploy Application"

#### 3. Configure API Manager

**For Each API:**

1. Navigate to API Manager
2. Click "Manage API from Exchange"
3. Select API and version
4. Configure:
   - Implementation URI: `https://<app-name>.cloudhub.io`
   - Proxy type: Basic Endpoint
5. Apply policies:
   - Client ID Enforcement
   - Rate Limiting (100 requests/minute)
   - IP Whitelist (optional)

#### 4. Verify Deployment

```bash
# System API
curl https://sys-magma-grmdm-gf-api-test.cloudhub.io/grmdm/companyfile/v1/health

# Process API
curl https://proc-magma-companyfile-gf-api-test.cloudhub.io/magma/companyfile/v1/health

# Experience API
curl https://exp-simp-companyfile-gf-api-test.cloudhub.io/simp/companyfile/v1/health \
  -H "client_id: <client-id>" \
  -H "client_secret: <client-secret>"
```

## Production Environment Deployment

### Pre-Production Steps

#### 1. Security Review

- [ ] Code security scan completed
- [ ] Dependency vulnerabilities resolved
- [ ] Penetration testing completed
- [ ] Security policies configured in API Manager

#### 2. Performance Testing

- [ ] Load testing completed (target: 100 TPS)
- [ ] Stress testing completed
- [ ] Connection pool sizing validated
- [ ] Response time SLAs met (< 2 seconds)

#### 3. Documentation

- [ ] API documentation published
- [ ] Runbook created
- [ ] Support procedures documented
- [ ] Rollback plan prepared

### CloudHub Production Deployment

#### 1. Environment Configuration

**System API**:
```properties
# prod.properties
mdm.integration.type=database
mdm.db.host=prod-mdm-db.company.com
mdm.db.port=1521
mdm.db.service.name=MDMPROD
mdm.db.pool.max.size=20
mdm.db.pool.min.size=5
http.listener.port=8443
http.request.response.timeout=180000
logging.level=WARN
```

**Process API**:
```properties
# prod.properties
system.api.host=prod-system-api.company.com
system.api.port=443
http.listener.port=8443
http.request.response.timeout=120000
logging.level=WARN
```

**Experience API**:
```properties
# prod.properties
process.api.host=prod-process-api.company.com
process.api.port=443
http.listener.port=8443
http.request.response.timeout=90000
logging.level=WARN
```

#### 2. Deploy with Maven

```bash
# System API
cd sys-magma-grmdm-gf-api
mvn clean deploy -DmuleDeploy \
  -Dmule.env=prod \
  -Danypoint.username=${ANYPOINT_USERNAME} \
  -Danypoint.password=${ANYPOINT_PASSWORD} \
  -Dapi.id=${SYSTEM_API_ID} \
  -Dsecure.key=${SECURE_KEY}

# Process API
cd ../proc-magma-companyfile-gf-api
mvn clean deploy -DmuleDeploy \
  -Dmule.env=prod \
  -Danypoint.username=${ANYPOINT_USERNAME} \
  -Danypoint.password=${ANYPOINT_PASSWORD} \
  -Dapi.id=${PROCESS_API_ID} \
  -Dsecure.key=${SECURE_KEY}

# Experience API
cd ../exp-simp-companyfile-gf-api
mvn clean deploy -DmuleDeploy \
  -Dmule.env=prod \
  -Danypoint.username=${ANYPOINT_USERNAME} \
  -Danypoint.password=${ANYPOINT_PASSWORD} \
  -Dapi.id=${EXPERIENCE_API_ID} \
  -Dsecure.key=${SECURE_KEY}
```

#### 3. Production Worker Configuration

```yaml
Application: sys-magma-grmdm-gf-api-prod
Runtime: 4.4.0
Workers: 2
Worker Size: 0.2 vCores (Small)
Static IPs: Enabled
Object Store V2: Enabled
Persistent Queues: Enabled
Monitoring: Enabled
Alerts: Configured
```

#### 4. API Manager Production Policies

Apply the following policies in order:

1. **Client ID Enforcement**
   - Required for all APIs
   - Credentials method: Custom Expression

2. **Rate Limiting**
   - Experience API: 1000 requests/minute
   - Process API: 2000 requests/minute
   - System API: 3000 requests/minute

3. **Spike Control**
   - Experience API: 100 requests/second
   - Window: 1 second

4. **IP Whitelist** (if required)
   - Add SIM-P source IP ranges

5. **Basic Authentication** (optional additional layer)

### Runtime Fabric Deployment

For on-premise deployments using Runtime Fabric:

#### 1. Build Docker Image

```bash
# Build Mule application
mvn clean package

# Create Dockerfile
FROM mulesoft/mule-runtime:4.4.0

COPY target/*.jar /opt/mule/apps/

EXPOSE 8081

CMD ["mule"]
```

#### 2. Deploy to Runtime Fabric

```bash
# Tag and push image
docker tag sys-magma-grmdm-gf-api:1.0.0 registry.company.com/sys-magma-grmdm-gf-api:1.0.0
docker push registry.company.com/sys-magma-grmdm-gf-api:1.0.0

# Deploy via Runtime Manager UI or CLI
anypoint-cli runtime-fabric deployment create \
  --name sys-magma-grmdm-gf-api-prod \
  --target prod-rtf-cluster \
  --runtime 4.4.0 \
  --replicas 2 \
  --properties mule.env=prod
```

## Post-Deployment Verification

### 1. Health Checks

```bash
# System API
curl https://sys-magma-grmdm-gf-api-prod.company.com/grmdm/companyfile/v1/health

Expected Response:
{
  "status": "UP",
  "apiName": "sys-magma-grmdm-gf-api",
  "version": "v1",
  "timestamp": "2025-11-11T10:30:00Z",
  "mdmConnection": "UP"
}
```

### 2. Integration Testing

```bash
# Test end-to-end flow
curl -X GET "https://api.company.com/simp/companyfile/v1/legalentities?country=US&limit=10" \
  -H "client_id: ${CLIENT_ID}" \
  -H "client_secret: ${CLIENT_SECRET}"

Expected: 200 OK with legal entities data
```

### 3. Performance Verification

```bash
# Run load test
ab -n 1000 -c 10 -H "client_id: ${CLIENT_ID}" -H "client_secret: ${CLIENT_SECRET}" \
  https://api.company.com/simp/companyfile/v1/legalentities

Expected:
- Requests per second: > 50
- Average response time: < 2000ms
- No errors
```

### 4. Monitoring Setup

- [ ] CloudWatch/Anypoint Monitoring dashboards configured
- [ ] Alerts configured for:
  - High error rate (> 5%)
  - High response time (> 3 seconds)
  - Low availability (< 99%)
  - Circuit breaker open
- [ ] Log aggregation configured (Splunk/ELK)
- [ ] APM integration configured

## Rollback Procedures

### CloudHub Rollback

1. Navigate to Runtime Manager
2. Select the application
3. Click on "Deployments" tab
4. Find previous successful deployment
5. Click "Redeploy"

### Maven Rollback

```bash
# Redeploy previous version
mvn clean deploy -DmuleDeploy \
  -Dmule.env=prod \
  -Dapp.version=1.0.0-PREVIOUS
```

### Manual Rollback

1. Stop current application
2. Upload previous JAR version
3. Update properties if needed
4. Start application
5. Verify health checks

## Troubleshooting

### Deployment Failures

**Issue**: Application won't start
```bash
# Check logs
anypoint-cli runtime-fabric logs sys-magma-grmdm-gf-api-prod

# Common causes:
- Missing/incorrect properties
- Invalid credentials
- Port conflicts
- Insufficient resources
```

**Issue**: API Autodiscovery fails
```bash
# Verify:
- api.id is correct in properties
- API exists in API Manager
- Anypoint credentials are valid
```

**Issue**: Database connection fails
```bash
# Verify:
- Database host/port accessible
- Credentials are correct
- Firewall rules allow connection
- Connection pool configuration
```

## Maintenance Windows

### Recommended Schedule

- **Deployments**: Sundays 2:00 AM - 4:00 AM EST
- **Certificate Renewal**: First Saturday of month
- **Patching**: Monthly security patches

### Deployment Notification

Send notification 48 hours before deployment:

```
Subject: Production Deployment - Company File APIs

Deployment Details:
- Date: [DATE]
- Time: 2:00 AM - 4:00 AM EST
- Duration: Up to 2 hours
- Impact: Brief service interruption (<5 minutes)
- Rollback Available: Yes

Changes:
- [List of changes]

Contact:
- Operations: mulesoft-ops@company.com
- Emergency: +1-xxx-xxx-xxxx
```

## Emergency Contacts

- **On-Call Engineer**: +1-xxx-xxx-xxxx
- **Manager**: +1-xxx-xxx-xxxx
- **MuleSoft Support**: support@mulesoft.com

## Appendix

### A. Required Anypoint Platform Permissions

- Runtime Manager Deploy
- API Manager Admin
- Exchange Contributor
- CloudHub Admin (for CloudHub deployments)

### B. Network Requirements

- Outbound HTTPS (443) to Anypoint Platform
- Outbound connection to MDM database (1521) or MDM API (443)
- Inbound HTTPS (8443) for API traffic
- Firewall rules for inter-API communication

### C. Estimated Deployment Times

| Environment | System API | Process API | Experience API | Total |
|-------------|------------|-------------|----------------|-------|
| Development | 5 min      | 5 min       | 5 min          | 15 min |
| Test        | 10 min     | 10 min      | 10 min         | 30 min |
| Production  | 15 min     | 15 min      | 15 min         | 45 min |

---

**Document Version**: 1.0
**Last Updated**: November 11, 2025
**Next Review**: February 11, 2026
