# Incident Response Runbook
## Scenario: RDS Database Accidentally Made Publicly Accessible

**Severity:** Critical  
**Owner:** Infrastructure Team  
**Last Updated:** 2025

---

## 1. Detection

The incident will be detected through one or more of the following:

- **CloudWatch EventBridge rule** `oceans-across-rds-public-access` fires when
  RDS-EVENT-0088 is triggered — this event fires specifically when an RDS instance
  is modified to become publicly accessible
- **SNS alert email** sent to the infrastructure team immediately
- **AWS Config rule** `rds-instance-public-access-check` flags non-compliant state
- Manual discovery during routine audit

**First signs to look for:**
- SNS alert email with subject containing `RDS-EVENT-0088`
- CloudWatch alarm state change notification
- Unexpected inbound connection attempts in RDS logs

---

## 2. Immediate Containment (First 15 minutes)

### Step 1 — Confirm the exposure
```bash
aws rds describe-db-instances \
  --db-instance-identifier oceans-across-payroll-db-dev \
  --query 'DBInstances[0].PubliclyAccessible' \
  --region eu-west-2
```
If this returns `true` — the database is exposed. Proceed immediately.

### Step 2 — Revoke public access
```bash
aws rds modify-db-instance \
  --db-instance-identifier oceans-across-payroll-db-dev \
  --no-publicly-accessible \
  --apply-immediately \
  --region eu-west-2
```

### Step 3 — Verify RDS security group has no public inbound rules
```bash
aws ec2 describe-security-groups \
  --group-ids <rds-security-group-id> \
  --query 'SecurityGroups[0].IpPermissions' \
  --region eu-west-2
```
If any rule shows `0.0.0.0/0` or `::/0` on port 5432 — remove it immediately:
```bash
aws ec2 revoke-security-group-ingress \
  --group-id <rds-security-group-id> \
  --protocol tcp \
  --port 5432 \
  --cidr 0.0.0.0/0 \
  --region eu-west-2
```

### Step 4 — Force rotate DB credentials
```bash
# Generate new password in Secrets Manager
aws secretsmanager rotate-secret \
  --secret-id oceans-across/database/master-password-dev \
  --region eu-west-2
```

---

## 3. Investigation (First Hour)

### Identify who made the change
```bash
# Check CloudTrail for ModifyDBInstance events in last 24 hours
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=ModifyDBInstance \
  --start-time $(date -d '24 hours ago' --iso-8601=seconds) \
  --region eu-west-2
```
Look for: who made the call (userIdentity), from what IP, at what time.

### Check for unauthorized connections during exposure window
```bash
# Check RDS PostgreSQL logs for connections
aws logs filter-log-events \
  --log-group-name /oceans-across/rds/dev \
  --filter-pattern "connection received" \
  --start-time <exposure-start-timestamp-ms> \
  --end-time <remediation-timestamp-ms> \
  --region eu-west-2
```
Document every connection source IP during the exposure window.

### Check for data exfiltration signs
- Unusually high `NetworkReceive` or `NetworkTransmit` metrics on RDS during window
- Large number of `SELECT` statements in slow query logs
- Any new IAM roles or users created around the same time

---

## 4. Recovery

- Confirm `publicly_accessible = false` is reflected in Terraform state:
```bash
terraform plan  # should show no drift
```
- If Terraform state shows drift — run `terraform apply` to reconcile
- Re-enable and verify all CloudWatch alarms are in OK state
- Confirm SNS topic subscriptions are active
- Rotate all application secrets as a precaution even if no breach confirmed

---

## 5. Post-Incident Actions

| Action | Owner | Timeline |
|--------|-------|----------|
| Write incident report | On-call engineer | Within 24 hours |
| Identify root cause | Infrastructure lead | Within 48 hours |
| Add AWS Config rule to auto-remediate | DevOps | Within 1 week |
| Review IAM permissions that allowed the change | Security | Within 1 week |
| Add deletion protection back if removed | DevOps | Immediately |
| Notify affected tenants if breach confirmed | Product + Legal | Immediately |
| Notify ICO if UK GDPR breach confirmed | Legal | Within 72 hours |

---

## 6. Prevention

- **Terraform** — `publicly_accessible = false` is enforced in code.
  Any attempt to change it creates a PR and requires review.
- **AWS Config** — `rds-instance-public-access-check` rule continuously monitors state
- **EventBridge rule** — fires within seconds of any RDS modification event
- **IAM** — restrict `rds:ModifyDBInstance` to only infrastructure team roles
- **SCPs** — in a multi-account setup, use Service Control Policies to deny
  `rds:ModifyDBInstance` with `PubliclyAccessible=true` at the org level