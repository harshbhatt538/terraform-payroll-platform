## Task 6 - UK Compliance Considerations

### 1. AWS-Native Controls for UK GDPR Compliance

The following controls are in place to comply with UK GDPR when storing
employee PII and bank data:

**Encryption**
- All RDS data is encrypted at rest using AES-256 (`storage_encrypted = true`)
- All S3 objects are encrypted at rest using SSE-AES256
- All EC2 root volumes are encrypted at rest
- RDS enforces SSL on all connections via `rds.force_ssl = 1` parameter group
- S3 bucket policy denies any request over plain HTTP (`aws:SecureTransport = false`)

**Access Control**
- IAM roles follow least-privilege - each tenant role can only access its own
  resources. No role has wildcard resource access.
- S3 bucket policies enforce prefix-level isolation as a second boundary -
  even if IAM logic fails, the bucket policy blocks cross-tenant access
- IMDSv2 is enforced on all EC2 instances to prevent credential theft via SSRF

**Audit Trail**
- AWS CloudTrail should be enabled across all regions to log every API call,
  including who accessed what data, when, and from where. This satisfies the
  UK GDPR requirement for demonstrable accountability.
- CloudWatch log groups retain application logs for 30 days and infrastructure
  logs for 90 days - sufficient for incident investigation and regulatory audit
- RDS PostgreSQL logs are exported to CloudWatch for query-level auditing

**Data Minimisation**
- Each tenant type (companies, bureaus, employees) only has access to the
  data scope their role requires - enforced at both IAM and application layer
- S3 versioning is enabled - this provides a recoverable audit trail of
  document changes without needing a separate audit table

---

### 2. Data Residency Within the UK/EU Region

All infrastructure is deployed exclusively in `eu-west-2` (London) - the AWS
region physically located in the United Kingdom.

The following measures ensure data never leaves this region:

- The AWS provider in `providers.tf` hardcodes `region = "eu-west-2"` -
  no resource can be accidentally created in another region via this configuration
- S3 bucket replication is not configured - data stays in eu-west-2 only
- RDS has no cross-region read replicas configured
- CloudWatch logs are regional by default - log data stays in eu-west-2
- Secrets Manager secrets are regional - credentials are stored in eu-west-2 only

In a production setup the following additional controls would be added:
- **AWS Config rule** `approved-amis-by-region` to prevent resource creation
  outside eu-west-2
- **SCP (Service Control Policy)** at the AWS Organisation level denying any
  action where `aws:RequestedRegion` is not `eu-west-2` - this is the strongest
  possible data residency enforcement and cannot be overridden by individual
  account administrators

---

### 3. Right to Erasure (Article 17 UK GDPR)

When an employee requests permanent deletion of their data across all services,
the following process is followed:

**Step 1 - Database**
- Identify all records linked to the employee's `tenant_id` and `employee_id`
  across all schemas
- Hard delete PII fields (name, NI number, bank account, address) from all tables
- For payroll records where legal retention applies (HMRC requires 3 years minimum),
  replace PII fields with anonymised tokens rather than deleting the row -
  this satisfies both the right to erasure and legal retention obligations simultaneously

**Step 2 - S3**
- Delete all objects under the employee's prefix (`employees/{employee_id}/*`)
- Because versioning is enabled, all previous versions must also be explicitly deleted -
  not just the current version. A lifecycle rule or explicit delete markers must be
  applied to all versions and delete markers.
- Confirm deletion with `aws s3api list-object-versions` to verify no versions remain

**Step 3 - Secrets Manager**
- Delete any secrets scoped to that employee
- Secrets Manager has a 7 day recovery window by default - for right to erasure,
  use `--force-delete-without-recovery` to delete immediately

**Step 4 - CloudWatch Logs**
- Identify any log streams containing the employee's PII (name, NI number, email)
- Delete those specific log events using `aws logs delete-log-group` or filter
  and re-ingest with PII removed
- Going forward - structured logging should never log raw PII, only anonymised IDs

**Step 5 - Audit Trail**
- Log the erasure event itself - who requested it, who executed it, timestamp,
  and confirmation that all systems were cleared
- This audit record itself contains no PII - only the erasure event metadata
- Retain this audit record indefinitely as proof of compliance

**Important caveat - legal retention vs erasure conflict:**
UK GDPR Article 17(3) allows retention of data where it is necessary for
compliance with a legal obligation. HMRC requires payroll records to be kept
for a minimum of 3 years. Where this conflict exists, PII should be anonymised
rather than deleted - the payroll record is retained but cannot be linked back
to the individual.