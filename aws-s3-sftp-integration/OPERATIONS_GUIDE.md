# Operations Guide - AWS S3 to SFTP Integration

## Quick Reference

### Application Information
- **Application Name**: aws-s3-sftp-integration
- **Version**: 1.0.0
- **Runtime**: Mule 4.4.0
- **Scheduler**: Daily batch job (midnight)
- **Processing Limit**: 8 CSV files per batch

## Daily Operations Checklist

### Morning Check (After Batch Runs)

1. **Verify Batch Completion**
   ```bash
   tail -100 logs/aws-s3-sftp-integration.log | grep "Batch job completed"
   ```
   Expected: Success message with processed file count

2. **Check Error Count**
   ```bash
   grep "Error processing file" logs/aws-s3-sftp-integration-error.log | wc -l
   ```
   Expected: 0 errors

3. **Verify Health Status**
   ```bash
   curl http://localhost:8081/health
   ```
   Expected: `{"status":"UP"}`

4. **Check S3 Input Folder**
   - Verify input folder is empty (files processed)
   - Check archive folder has timestamped files
   - Review error folder for failed files

5. **Verify SFTP Delivery**
   - Login to SFTP server
   - Confirm files in /Target folder
   - Validate file count matches processed count

## Common Tasks

### View Recent Logs
```bash
# Last 50 log entries
tail -50 logs/aws-s3-sftp-integration.log

# Real-time log monitoring
tail -f logs/aws-s3-sftp-integration.log

# Error logs only
tail -50 logs/aws-s3-sftp-integration-error.log

# Search for specific file
grep "employee_001.csv" logs/aws-s3-sftp-integration.log
```

### Check Application Status
```bash
# CloudHub
curl -X GET \
  "https://anypoint.mulesoft.com/cloudhub/api/v2/applications/aws-s3-sftp-integration" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"

# On-Premises
$MULE_HOME/bin/mule status

# Health endpoint
curl http://localhost:8081/health
```

### Restart Application
```bash
# CloudHub
curl -X POST \
  "https://anypoint.mulesoft.com/cloudhub/api/v2/applications/aws-s3-sftp-integration/restart" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}"

# On-Premises
$MULE_HOME/bin/mule restart
```

### Manual File Processing (Emergency)

If files are stuck and need immediate processing:

1. **Check current files**
   ```bash
   aws s3 ls s3://employee-data-prod/input/
   ```

2. **Manually trigger** (if REST endpoint added):
   ```bash
   curl -X POST http://localhost:8081/trigger-batch
   ```

3. **Alternative - Wait for next scheduled run** (24 hours)

## Monitoring Metrics

### Key Performance Indicators (KPIs)

| Metric | Target | Alert Threshold |
|--------|--------|-----------------|
| Files Processed/Day | 8 | < 6 |
| Processing Success Rate | 100% | < 95% |
| Average Processing Time | < 2 min | > 5 min |
| Error Rate | 0% | > 5% |
| Batch Completion Time | < 2 min | > 10 min |

### CloudHub Metrics
Access via: Anypoint Platform → Runtime Manager → Application → Dashboard

Monitor:
- CPU Usage (target: < 70%)
- Memory Usage (target: < 80%)
- Message Count
- Error Rate
- Response Time

### Log Analysis Queries

```bash
# Count successful file transfers today
grep "Successfully transferred file to SFTP" logs/aws-s3-sftp-integration.log | \
  grep "$(date +%Y-%m-%d)" | wc -l

# List all processed files today
grep "Processing file:" logs/aws-s3-sftp-integration.log | \
  grep "$(date +%Y-%m-%d)" | \
  awk -F'Processing file: ' '{print $2}'

# Average processing time per file
grep "Duration:" logs/aws-s3-sftp-integration.log | \
  grep "$(date +%Y-%m-%d)" | \
  awk '{sum+=$NF; count++} END {print sum/count " seconds"}'

# Error types summary
grep "errorType" logs/aws-s3-sftp-integration-error.log | \
  jq -r '.errorType' | sort | uniq -c
```

## Incident Response

### Scenario 1: No Files Processed

**Symptoms**: Batch runs but processes 0 files

**Diagnosis Steps**:
1. Check if files exist in S3 input folder
2. Verify S3 credentials are valid
3. Check IAM permissions for ListBucket
4. Review application logs for errors

**Resolution**:
```bash
# Verify S3 access
aws s3 ls s3://employee-data-prod/input/ --profile mule-prod

# Check IAM permissions
aws iam get-user-policy --user-name mule-s3-user --policy-name S3Access

# If credentials expired, update in properties
# Then restart application
```

### Scenario 2: SFTP Connection Failed

**Symptoms**: `SFTP:CONNECTIVITY` errors in logs

**Diagnosis Steps**:
1. Test SFTP connectivity manually
2. Check firewall rules
3. Verify SFTP credentials
4. Check SFTP server status

**Resolution**:
```bash
# Test SFTP manually
sftp -P 22 username@sftp-prod.example.com

# Check network connectivity
telnet sftp-prod.example.com 22

# If SFTP is down, contact SFTP team
# If credentials invalid, update in secure properties
```

### Scenario 3: Files in Error Folder

**Symptoms**: Files present in S3 error/ folder

**Diagnosis Steps**:
1. Review error logs for specific file
2. Download file from error folder
3. Validate file format
4. Check file size

**Resolution**:
```bash
# Download error file
aws s3 cp s3://employee-data-prod/error/employee_001_20250115_120000.csv ./

# Validate CSV format
file employee_001_20250115_120000.csv

# If valid, manually move to input folder for reprocessing
aws s3 cp ./employee_001_20250115_120000.csv s3://employee-data-prod/input/employee_001.csv

# If corrupt, contact source system team
```

### Scenario 4: High Memory Usage

**Symptoms**: Application slow, memory alerts

**Diagnosis Steps**:
1. Check file sizes in current batch
2. Review heap memory usage
3. Check for memory leaks

**Resolution**:
```bash
# CloudHub - Increase worker size
# Settings → Properties → Worker Size: SMALL → MEDIUM

# On-Premises - Increase JVM heap
# Edit wrapper.conf:
wrapper.java.additional.N=-Xmx4096m

# Restart application
```

### Scenario 5: Application Not Starting

**Symptoms**: Application shows stopped/failed status

**Diagnosis Steps**:
1. Check deployment logs
2. Verify dependencies
3. Check configuration errors
4. Validate secure properties

**Resolution**:
```bash
# Check logs
tail -100 logs/mule.log

# Common issues:
# - Missing secure.key file
# - Invalid property values
# - Port conflicts (8081)

# Fix configuration and redeploy
mvn clean package
$MULE_HOME/bin/mule restart
```

## Maintenance Windows

### Weekly Maintenance
- Review error logs
- Analyze performance metrics
- Check S3 archive folder size
- Verify SFTP connectivity

### Monthly Maintenance
- Review and rotate logs
- Update monitoring dashboards
- Test disaster recovery procedures
- Review security configurations

### Quarterly Maintenance
- Credential rotation (AWS, SFTP)
- Dependency updates (if applicable)
- Performance tuning review
- Capacity planning review

## Escalation Procedures

### Level 1 - Operations Team
- Handle routine monitoring
- Respond to alerts
- Perform health checks
- Restart application if needed

### Level 2 - Integration Team
- Investigate application errors
- Fix configuration issues
- Analyze log files
- Coordinate with external teams

### Level 3 - MuleSoft Architects
- Complex technical issues
- Performance optimization
- Architecture changes
- Major incident response

## Contact Information

| Role | Contact | Hours |
|------|---------|-------|
| Operations Team | ops-team@example.com | 24/7 |
| Integration Team | dev-team@example.com | Mon-Fri 9-5 |
| AWS Support | aws-admin@example.com | 24/7 |
| SFTP Team | sftp-admin@example.com | Mon-Fri 9-5 |
| MuleSoft Support | support@mulesoft.com | 24/7 (Premium) |

## Backup and Recovery

### Backup Locations
- **Application Code**: Git repository
- **Deployment Artifacts**: Nexus/Artifactory
- **S3 Archives**: `s3://employee-data-prod/archive/`
- **Configuration**: Secure vault

### Recovery Time Objectives (RTO)
- **Application Restart**: 5 minutes
- **Full Redeployment**: 30 minutes
- **Disaster Recovery**: 4 hours

### Recovery Point Objectives (RPO)
- **S3 Archives**: 0 minutes (real-time)
- **Configuration**: 1 hour
- **Application Code**: 0 minutes (Git)

## Compliance and Auditing

### Audit Log Retention
- **Application Logs**: 30 days
- **Error Logs**: 30 days
- **Audit Logs**: 90 days
- **S3 Archives**: 7 years (compliance requirement)

### Compliance Checks
- Monthly audit log review
- Quarterly access review
- Annual compliance certification
- Regular security scans

## Performance Baselines

### Normal Operation Metrics

| Metric | Baseline | Updated |
|--------|----------|---------|
| Avg Files/Day | 8 | - |
| Avg File Size | 2 MB | - |
| Avg Processing Time | 1.5 min | - |
| Peak Memory Usage | 512 MB | - |
| Peak CPU Usage | 45% | - |

Update this section monthly with actual metrics.

---

**Document Version**: 1.0
**Last Updated**: January 15, 2025
**Next Review**: February 15, 2025
