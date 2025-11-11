# Deployment Guide - MDM to ERS Real Estate Integration

## Table of Contents
1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Environment Setup](#environment-setup)
3. [Database Setup](#database-setup)
4. [Deployment Steps](#deployment-steps)
5. [Post-Deployment Verification](#post-deployment-verification)
6. [Rollback Procedures](#rollback-procedures)

---

## Pre-Deployment Checklist

### Infrastructure Requirements

- [ ] CloudHub account with sufficient vCore allocation OR On-premise Mule Runtime 4.6.0+
- [ ] Network connectivity to:
  - MDM Oracle Database
  - GRMDM Oracle Database
  - ERS SAP HANA Database
- [ ] SSL certificates configured
- [ ] Firewall rules updated for API ports

### Access Requirements

- [ ] Anypoint Platform credentials
- [ ] Database credentials (MDM, GRMDM, ERS)
- [ ] API client credentials generated
- [ ] Encryption keys for secure properties

### Code Preparation

- [ ] All code reviewed and approved
- [ ] Unit tests passed (minimum 75% coverage)
- [ ] Integration tests completed
- [ ] Security scan completed
- [ ] Documentation updated

---

## Environment Setup

### 1. Configure Environment Properties

For each environment (dev, test, prod), update the properties files:

**exp-mdm-realestate-gf-api**:
```bash
vi mulesoft-projects/exp-mdm-realestate-gf-api/src/main/resources/properties/prod.properties
```

Update:
- Database connection details (host, port, credentials)
- API endpoints for downstream services
- Security credentials
- Connection pool sizes
- Timeout values

**Repeat for all APIs**:
- proc-magma-companyfile-gf-api
- sys-magma-grmdm-gf-api
- sys-ers-realestate-gf-api

### 2. Encrypt Sensitive Properties

```bash
# Example: Encrypt database password
java -cp ~/.m2/repository/com/mulesoft/modules/mule-secure-configuration-property-module/1.2.7/mule-secure-configuration-property-module-1.2.7-mule-plugin.jar \
  com.mulesoft.modules.secure.tools.SecurePropertiesTool \
  string encrypt Blowfish CBC <your-encryption-key> <database-password>
```

Create secure properties files:
```bash
# Create secure-prod.properties for each API
echo "mdm.db.password=![encrypted-value]" > secure-prod.properties
```

### 3. Set Environment Variables

For CloudHub deployment:
```bash
export ANYPOINT_USERNAME="your-username"
export ANYPOINT_PASSWORD="your-password"
export ANYPOINT_ENV="Production"
export ENCRYPTION_KEY="your-encryption-key"
```

---

## Database Setup

### 1. MDM Database (Oracle)

Create the required table structure:

```sql
-- Connect to MDM database
sqlplus mdm_reader/password@mdm-prod:1521/MDMPROD

-- Verify table exists
SELECT COUNT(*) FROM MDM_REAL_ESTATE_PROPERTIES;

-- Expected columns:
-- PROPERTY_ID, PROPERTY_TYPE, STREET, CITY, STATE, POSTAL_CODE, COUNTRY,
-- CURRENT_VALUE, CURRENCY, VALUATION_DATE, VALUATION_METHOD,
-- OWNER_ID, OWNER_NAME, OWNERSHIP_TYPE, ACQUISITION_DATE,
-- STATUS, CREATED_DATE, LAST_MODIFIED_DATE, SOURCE
```

### 2. GRMDM Database (Oracle)

```sql
-- Connect to GRMDM database
sqlplus grmdm_user/password@grmdm-prod:1521/GRMDMPROD

-- Verify table exists
SELECT COUNT(*) FROM GRMDM_COMPANIES;

-- Expected columns:
-- COMPANY_ID, COMPANY_NAME, STATUS, CREATED_DATE
```

### 3. ERS Database (SAP HANA)

```sql
-- Connect to SAP HANA
hdbsql -u ERS_API_USER -p password -n ers-hana-prod:30015 -d ERSPROD

-- Create schema if not exists
CREATE SCHEMA ERS_REALESTATE;

-- Create table
CREATE COLUMN TABLE ERS_REALESTATE.REAL_ESTATE_PROPERTIES (
    PROPERTY_ID VARCHAR(50) PRIMARY KEY,
    PROPERTY_TYPE VARCHAR(50) NOT NULL,
    STREET VARCHAR(200),
    CITY VARCHAR(100),
    STATE VARCHAR(50),
    POSTAL_CODE VARCHAR(20),
    COUNTRY VARCHAR(50),
    CURRENT_VALUE DECIMAL(18,2),
    CURRENCY VARCHAR(3),
    VALUATION_DATE TIMESTAMP,
    OWNER_ID VARCHAR(50),
    OWNER_NAME VARCHAR(200),
    STATUS VARCHAR(20),
    SOURCE_SYSTEM VARCHAR(50),
    CREATED_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    LAST_MODIFIED_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX IDX_PROP_TYPE ON ERS_REALESTATE.REAL_ESTATE_PROPERTIES(PROPERTY_TYPE);
CREATE INDEX IDX_STATUS ON ERS_REALESTATE.REAL_ESTATE_PROPERTIES(STATUS);
CREATE INDEX IDX_LAST_MOD ON ERS_REALESTATE.REAL_ESTATE_PROPERTIES(LAST_MODIFIED_DATE);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ERS_REALESTATE.REAL_ESTATE_PROPERTIES TO ERS_API_USER;
```

---

## Deployment Steps

### Option 1: CloudHub Deployment

#### Deploy All APIs to CloudHub

```bash
#!/bin/bash
# deploy-to-cloudhub.sh

APIS=("exp-mdm-realestate-gf-api" "proc-magma-companyfile-gf-api" "sys-magma-grmdm-gf-api" "sys-ers-realestate-gf-api")

for API in "${APIS[@]}"; do
    echo "Deploying $API to CloudHub..."

    cd mulesoft-projects/$API

    mvn clean deploy -DmuleDeploy \
        -Denv=prod \
        -Danypoint.username=$ANYPOINT_USERNAME \
        -Danypoint.password=$ANYPOINT_PASSWORD \
        -Danypoint.environment=$ANYPOINT_ENV \
        -Danypoint.applicationName=$API \
        -Danypoint.workers=1 \
        -Danypoint.workerType=MICRO \
        -Danypoint.region=us-east-2 \
        -Dencryption.key=$ENCRYPTION_KEY

    if [ $? -eq 0 ]; then
        echo "✓ $API deployed successfully"
    else
        echo "✗ $API deployment failed"
        exit 1
    fi

    cd ../..
done

echo "All APIs deployed successfully!"
```

Run the deployment:
```bash
chmod +x deploy-to-cloudhub.sh
./deploy-to-cloudhub.sh
```

#### Monitor Deployment

```bash
# Check deployment status via Anypoint CLI
anypoint-cli runtime-mgr cloudhub-application describe exp-mdm-realestate-gf-api
```

### Option 2: On-Premise Deployment

#### Build Deployable Archives

```bash
#!/bin/bash
# build-all.sh

APIS=("exp-mdm-realestate-gf-api" "proc-magma-companyfile-gf-api" "sys-magma-grmdm-gf-api" "sys-ers-realestate-gf-api")

for API in "${APIS[@]}"; do
    echo "Building $API..."
    cd mulesoft-projects/$API
    mvn clean package -Denv=prod
    cd ../..
done

echo "Build completed. Deployment archives in target/ directories."
```

#### Deploy to Mule Runtime

```bash
#!/bin/bash
# deploy-to-runtime.sh

MULE_HOME="/opt/mule-enterprise-standalone-4.6.0"
APIS=("exp-mdm-realestate-gf-api" "proc-magma-companyfile-gf-api" "sys-magma-grmdm-gf-api" "sys-ers-realestate-gf-api")

for API in "${APIS[@]}"; do
    echo "Deploying $API to Mule Runtime..."

    # Copy deployment archive
    cp mulesoft-projects/$API/target/$API-1.0.0-mule-application.jar \
       $MULE_HOME/apps/

    # Wait for deployment
    sleep 30

    # Check deployment status
    if [ -f "$MULE_HOME/apps/$API-1.0.0-mule-application-anchor.txt" ]; then
        echo "✓ $API deployed successfully"
    else
        echo "✗ $API deployment failed"
        exit 1
    fi
done

echo "All APIs deployed to Mule Runtime!"
```

Run deployment:
```bash
chmod +x build-all.sh deploy-to-runtime.sh
./build-all.sh
./deploy-to-runtime.sh
```

---

## Post-Deployment Verification

### 1. Health Checks

Verify all APIs are healthy:

```bash
#!/bin/bash
# health-check.sh

APIS=(
    "http://exp-mdm-realestate-gf-api.cloudhub.io/api/mdm/realestate/v1/health"
    "http://proc-magma-companyfile-gf-api.cloudhub.io/api/proc/magma/companyfile/v1/health"
    "http://sys-magma-grmdm-gf-api.cloudhub.io/sys/magma/grmdm/v1/health"
    "http://sys-ers-realestate-gf-api.cloudhub.io/sys/ers/realestate/v1/health"
)

for URL in "${APIS[@]}"; do
    echo "Checking: $URL"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" $URL)

    if [ $RESPONSE -eq 200 ]; then
        echo "✓ Healthy"
    else
        echo "✗ Unhealthy (HTTP $RESPONSE)"
    fi
    echo ""
done
```

### 2. Smoke Tests

#### Test MDM Experience API
```bash
curl -X GET \
  'https://exp-mdm-realestate-gf-api.cloudhub.io/api/mdm/realestate/v1/properties?limit=5' \
  -H 'client_id: prod_client_id' \
  -H 'client_secret: prod_client_secret' \
  -H 'x-correlation-id: test-001'
```

Expected: HTTP 200 with property data

#### Test Processing API
```bash
curl -X POST \
  'https://proc-magma-companyfile-gf-api.cloudhub.io/api/proc/magma/companyfile/v1/process' \
  -H 'Content-Type: application/json' \
  -H 'client_id: prod_client_id' \
  -H 'client_secret: prod_client_secret' \
  -d '{
    "processType": "REAL_ESTATE_SYNC",
    "sourceSystem": "MDM",
    "targetSystem": "ERS",
    "options": {
      "batchSize": 10
    }
  }'
```

Expected: HTTP 202 with process ID

#### Test ERS System API
```bash
# Create a test property
curl -X POST \
  'https://sys-ers-realestate-gf-api.cloudhub.io/sys/ers/realestate/v1/properties' \
  -H 'Content-Type: application/json' \
  -H 'client_id: prod_client_id' \
  -H 'client_secret: prod_client_secret' \
  -d '{
    "propertyId": "TEST-001",
    "propertyType": "COMMERCIAL",
    "address": {
      "street": "123 Test St",
      "city": "Test City",
      "state": "TC",
      "postalCode": "12345",
      "country": "USA"
    },
    "valuation": {
      "currentValue": 100000,
      "currency": "USD",
      "valuationDate": "2025-01-15T10:00:00Z"
    },
    "ownership": {
      "ownerId": "TEST-OWNER",
      "ownerName": "Test Owner"
    },
    "status": "ACTIVE",
    "sourceSystem": "MDM"
  }'
```

Expected: HTTP 201 with success message

### 3. End-to-End Integration Test

```bash
#!/bin/bash
# e2e-test.sh

echo "=== End-to-End Integration Test ==="
echo ""

# Step 1: Fetch data from MDM
echo "1. Fetching property from MDM..."
MDM_RESPONSE=$(curl -s -X GET \
  'https://exp-mdm-realestate-gf-api.cloudhub.io/api/mdm/realestate/v1/properties?limit=1' \
  -H 'client_id: prod_client_id' \
  -H 'client_secret: prod_client_secret')

PROPERTY_ID=$(echo $MDM_RESPONSE | jq -r '.data[0].propertyId')
echo "   Property ID: $PROPERTY_ID"

# Step 2: Trigger processing
echo "2. Triggering batch processing..."
PROCESS_RESPONSE=$(curl -s -X POST \
  'https://proc-magma-companyfile-gf-api.cloudhub.io/api/proc/magma/companyfile/v1/process' \
  -H 'Content-Type: application/json' \
  -H 'client_id: prod_client_id' \
  -H 'client_secret: prod_client_secret' \
  -d '{"processType":"REAL_ESTATE_SYNC","sourceSystem":"MDM","targetSystem":"ERS"}')

PROCESS_ID=$(echo $PROCESS_RESPONSE | jq -r '.processId')
echo "   Process ID: $PROCESS_ID"

# Step 3: Wait for processing
echo "3. Waiting for processing to complete..."
sleep 60

# Step 4: Verify in ERS
echo "4. Verifying property in ERS..."
ERS_RESPONSE=$(curl -s -X GET \
  "https://sys-ers-realestate-gf-api.cloudhub.io/sys/ers/realestate/v1/properties/$PROPERTY_ID" \
  -H 'client_id: prod_client_id' \
  -H 'client_secret: prod_client_secret')

if echo $ERS_RESPONSE | jq -e '.propertyId' > /dev/null; then
    echo "   ✓ Property found in ERS"
    echo ""
    echo "=== Integration Test PASSED ==="
else
    echo "   ✗ Property not found in ERS"
    echo ""
    echo "=== Integration Test FAILED ==="
    exit 1
fi
```

### 4. Monitoring Setup

Configure monitoring in Anypoint Platform:

1. **Application Metrics**:
   - CPU usage alerts (> 80%)
   - Memory usage alerts (> 85%)
   - Response time alerts (> 3s)

2. **API Analytics**:
   - Request volume
   - Error rates
   - Average response time

3. **Custom Alerts**:
   - Database connectivity failures
   - Processing failures
   - Batch job completions

---

## Rollback Procedures

### CloudHub Rollback

```bash
#!/bin/bash
# rollback-cloudhub.sh

API_NAME="exp-mdm-realestate-gf-api"
PREVIOUS_VERSION="1.0.0"

# Rollback using Anypoint CLI
anypoint-cli runtime-mgr cloudhub-application modify $API_NAME \
    --runtime 4.6.0 \
    --file target/$API_NAME-$PREVIOUS_VERSION-mule-application.jar \
    --environment Production
```

### On-Premise Rollback

```bash
#!/bin/bash
# rollback-runtime.sh

MULE_HOME="/opt/mule-enterprise-standalone-4.6.0"
API_NAME="exp-mdm-realestate-gf-api"
BACKUP_DIR="/opt/mule-backups"

# Stop application
touch $MULE_HOME/apps/$API_NAME-1.0.0-mule-application-anchor.txt.bak

# Wait for undeploy
sleep 30

# Restore previous version
cp $BACKUP_DIR/$API_NAME-previous.jar $MULE_HOME/apps/

# Wait for deployment
sleep 30

echo "Rollback completed"
```

### Database Rollback

If data corruption occurs in ERS:

```sql
-- Connect to ERS SAP HANA
hdbsql -u ERS_API_USER -p password -n ers-hana-prod:30015 -d ERSPROD

-- Delete records created since deployment
DELETE FROM ERS_REALESTATE.REAL_ESTATE_PROPERTIES
WHERE CREATED_DATE >= '2025-01-15 10:00:00';

-- Or restore from backup
-- (Backup should be taken before deployment)
```

---

## Troubleshooting Common Issues

### Issue: API Not Responding

**Symptoms**: HTTP 503 or connection timeout

**Resolution**:
1. Check application status in Runtime Manager
2. Review application logs
3. Verify database connectivity
4. Check memory/CPU usage
5. Restart application if necessary

### Issue: Database Connection Failures

**Symptoms**: DB:CONNECTIVITY errors in logs

**Resolution**:
1. Verify database is accessible:
   ```bash
   telnet ers-hana-prod.database.local 30015
   ```
2. Check credentials in properties
3. Verify firewall rules
4. Check connection pool settings

### Issue: High Error Rates

**Symptoms**: Increased 500 errors

**Resolution**:
1. Review error logs for specific errors
2. Check correlation IDs for failed requests
3. Verify downstream service availability
4. Review recent code changes
5. Consider rollback if critical

---

## Support Contacts

- **Production Issues**: prod-support@organization.com
- **Deployment Questions**: devops@organization.com
- **Emergency**: +1-xxx-xxx-xxxx (24/7 on-call)

---

**Document Version**: 1.0
**Last Updated**: 2025-01-15
**Next Review**: 2025-04-15
