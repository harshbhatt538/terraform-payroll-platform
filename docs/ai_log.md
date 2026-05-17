# AI Usage Log

**Candidate:** Harsh Bhatt 
**Assignment:** DevOps Engineer 
**AI Tools Used:** Claude (Anthropic), chatgpt 
**Log Format:** Prompt → Key Output Taken → What I Changed/Rejected/Why

---

## Task 1 - AWS Infrastructure Setup

---

### Prompt 1.1 - Module Structure Decision

**Prompt:**
> I'm designing AWS infrastructure for a multi-tenant UK payroll platform using
> Terraform. I want a VPC with public/private subnets across 2 AZs, 3 EC2 t3.micro
> instances (one each for Companies, Bureaus, Employees portals), RDS PostgreSQL
> db.t3.micro in a private subnet, S3 with versioning, and tenant-scoped IAM roles.
> Security Groups and NACLs should isolate tenant traffic. Before writing any
> Terraform, give me the module structure you'd recommend for this - I want to decide
> if I should split by resource type or by tenant. Don't write code yet.

**Key Output Taken:**
AI recommended two options - resource-type modules (vpc, compute, database, storage,
iam) vs tenant-based modules (companies/, bureaus/, employees/).

**What I Changed/Decided:**
Chose resource-type modules. Tenants share the VPC and RDS instance - splitting by
tenant would mean duplicating vpc and database modules unnecessarily. Resource-type
modules are more maintainable and reflect how AWS resources actually map. Tenant
isolation is handled within each module via security groups and IAM, not by
duplicating the module structure.

---

### Prompt 1.2 - VPC Module

**Prompt:**
> I'll go with resource-type based modules since tenants share the VPC but need
> isolated security groups. Now write the vpc module - include CIDR blocks,
> public/private subnets across two AZs, Internet Gateway, NAT Gateway, route
> tables, and NACLs for private subnets. Use eu-west-2 as the region since this
> is a UK platform. Restrict NACL outbound to ports 443, 5432, and ephemeral
> ports 1024-65535 only.

**Key Output Taken:**
Full vpc module with subnets, IGW, NAT Gateway, route tables, and NACLs.

**What I Changed/Rejected:**
- Changed region from us-east-1 (AI default) to eu-west-2 - UK data residency
  requirement, not just a preference
- AI initially allowed all outbound on NACLs. I restricted outbound to 443, 5432,
  and ephemeral ports only - principle of least privilege at the network layer
- Added comments explaining why ephemeral ports are needed - return traffic for
  outbound TCP connections requires ports 1024-65535, without this rule responses
  are silently dropped by the NACL

---

### Prompt 1.3 - IAM Module

**Prompt:**
> Write the Terraform IAM module. Create three IAM roles - one per tenant type
> (companies, bureaus, employees). Each role should be assumable by EC2 via instance
> profile. Scope each role's S3 access strictly to its own prefix. Add an explicit
> Deny on other tenant prefixes - I want two enforcement boundaries, not one. Scope
> Secrets Manager access by path per tenant. No wildcard resource access anywhere.

**Key Output Taken:**
Three IAM roles with scoped S3 policies, explicit Deny statements, and scoped
Secrets Manager policies.

**What I Changed/Rejected:**
- AI's first draft used wildcard S3 resource (`arn:aws:s3:::bucket/*`) on the Allow
  statements. I rejected this - it would allow a companies role to read bureaus/
  objects if the Deny was somehow misconfigured. Changed to explicit prefix ARNs only.
- Added explicit Deny statements myself - AI only added Allow. The Deny ensures that
  even if a future policy change accidentally grants broader access, the Deny takes
  precedence and blocks cross-tenant access at the IAM layer.
- Scoped Secrets Manager by path (`test/companies/*`) - AI initially gave
  access to all secrets. A companies EC2 has no business reading employees secrets.

---

### Prompt 1.4 - Compute Module

**Prompt:**
> Write the Terraform compute module. Create 3 EC2 t3.micro instances - one each
> for companies, bureaus, and employees portals. Each should be in a private subnet
> with no public IP. Create a separate security group per tenant - no inter-tenant
> traffic allowed. Enforce IMDSv2 on all instances. Encrypt root volumes. Associate
> each instance with its tenant IAM instance profile.

**Key Output Taken:**
Three EC2 instances with separate security groups, private subnet placement,
and IAM instance profile association.

**What I Changed/Added:**
- Added IMDSv2 enforcement (`http_tokens = required`) - this was not in AI's first
  draft. IMDSv1 is vulnerable to SSRF attacks where a compromised application can
  call the metadata endpoint and steal the instance's IAM credentials. IMDSv2
  requires a session token which SSRF cannot obtain.
- Distributed instances across AZs - companies and bureaus in AZ1, employees in AZ2.
  AI placed all three in the same subnet. Spreading across AZs improves resilience
  at no extra cost.
- Added encrypted root volumes - AI omitted this. EBS encryption at rest is required
  for a platform storing PII.

---

### Prompt 1.5 - Database Module

**Prompt:**
> Write the Terraform database module. PostgreSQL RDS db.t3.micro in private subnet.
> Generate the master password using random_password and store it in Secrets Manager
> - never hardcode it. Enable encryption at rest. Set publicly_accessible to false.
> Use a dynamic ingress block on the RDS security group that takes a list of EC2
> security group IDs - I want this to be extensible if we add more tenants later.
> Multi-AZ disabled for dev. 7 day backup retention. Export PostgreSQL logs to
> CloudWatch.

**Key Output Taken:**
Full database module with Secrets Manager integration, random_password, dynamic
security group ingress, and CloudWatch log exports.

**What I Changed/Added:**
- Requested dynamic ingress block specifically - AI's first draft had three hardcoded
  ingress rules. Dynamic block means adding a fourth tenant later requires only
  passing one more security group ID, not editing the module.
- Set `deletion_protection = false` for dev but added a comment flagging it must be
  `true` in production - AI didn't include this distinction.
- Marked `rds_endpoint` and `db_secret_arn` outputs as `sensitive = true` - AI
  omitted this. Without it Terraform prints these values in plain text in CI/CD logs.
- Added `random` provider to providers.tf after noticing the database module required
  it but the root providers.tf didn't declare it - AI missed this dependency.

---

### Prompt 1.6 - Storage Module

**Prompt:**
> Write the Terraform storage module. One S3 bucket with versioning enabled,
> AES-256 server-side encryption, all public access blocked. Write a bucket policy
> that enforces prefix-level isolation - companies role can only access companies/
> prefix, bureaus role only bureaus/, employees role only employees/. Add a
> DenyNonHTTPS statement that rejects any request not using SSL. Add a lifecycle
> policy for old versions.

**Key Output Taken:**
Full storage module with versioning, encryption, prefix-scoped bucket policy,
DenyNonHTTPS statement, and lifecycle configuration.

**What I Changed/Added:**
- Added DenyNonHTTPS bucket policy statement - AI's first draft didn't include it.
  This enforces encryption in transit at the bucket level regardless of client
  configuration. Any HTTP request is rejected.
- Added lifecycle policy to transition old versions to STANDARD_IA after 30 days
  and expire after 365 days - not in the original prompt but necessary for a payroll
  platform where payslips accumulate over time and storage costs compound.
- Added `depends_on` on the bucket policy pointing to the public access block -
  AWS requires public access block to be applied before bucket policies that
  reference public access settings. AI missed this dependency.

---

## Task 2 - Multi-Tenancy Architecture

---

### Prompt 2.1 - Tenancy Model Decision

**Prompt:**
> I need to choose a tenancy model for a UK payroll platform storing highly sensitive
> PII - employee bank details, NI numbers, payroll records. Options are: shared
> database with tenant_id column scoping, schema-per-tenant, or database-per-tenant.
> Give me the trade-offs for each in the context of a payroll platform specifically.
> Don't recommend yet - I want to make the decision myself.

**Key Output Taken:**
Trade-off analysis of all three models covering security, operational complexity,
cost, and isolation strength.

**What I Decided:**
Chose schema-per-tenant. Reasoning:
- Shared tables with tenant_id: too risky for payroll - a single missing WHERE clause
  leaks another tenant's salary data. Application bugs become data breaches.
- Database-per-tenant: strongest isolation but requires three RDS instances which
  exceeds free tier and adds significant operational overhead for a platform at
  this stage.
- Schema-per-tenant: strong isolation - a query running in the wrong schema returns
  zero rows by design, not by accident. Single RDS instance stays within free tier.
  PostgreSQL search_path makes tenant context enforcement clean and auditable.

---

### Prompt 2.2 - README Documentation for Task 2

**Prompt:**
> Write the Task 2 README section covering: why I chose schema-per-tenant, how
> tenant context is established at login via JWT and propagated by setting
> PostgreSQL search_path per request, how cross-tenant leakage is prevented even
> if application logic fails, how IAM and S3 bucket policies act as the
> infrastructure-layer boundary, and how tenant onboarding and offboarding works.
> Reference the Terraform modules already written where relevant.

**Key Output Taken:**
Full Task 2 README section covering 2a, 2b, and 2c.

**What I Changed:**
- Added the legal retention vs erasure conflict note in offboarding - AI's draft
  said "delete all data on offboarding" without acknowledging that HMRC requires
  payroll records for 3 years minimum. Blanket deletion would put the platform in
  breach of tax law. Corrected to anonymise PII while retaining the payroll record.

---

## Task 3 - Security & Access Control

---

### Prompt 3.1 - SSL Enforcement on RDS

**Prompt:**
> Write a Terraform RDS parameter group that forces SSL on all PostgreSQL connections.
> The parameter is rds.force_ssl and should be set to 1. Show me how to attach it
> to the existing RDS instance in the database module.

**Key Output Taken:**
`aws_db_parameter_group` resource with `rds.force_ssl = 1` and attachment to
the RDS instance via `parameter_group_name`.

**What I Changed:**
Nothing - this was a precise targeted prompt for a specific gap. Output was correct
and applied directly.

---

### Prompt 3.2 - Secret Injection Example

**Prompt:**
> Write a Python function showing how an application reads DB credentials from
> Secrets Manager at runtime. The secret name should come from an environment
> variable, not be hardcoded. The password should never be logged or printed.
> Show this as a reference implementation for docs/secret_injection_example.py.

**Key Output Taken:**
Python function using boto3 to fetch and parse Secrets Manager secret at runtime.

**What I Changed:**
- Added a comment explicitly noting the password key is never logged - AI's draft
  had no comment on this. For a payroll platform the distinction between logging
  the secret name vs logging the secret value needs to be explicit in the code.

---

### Prompt 3.3 - Task 3 README Section

**Prompt:**
> Write the Task 3 README section covering: IAM least-privilege with explicit Deny
> statements, how Secrets Manager is used with no hardcoded credentials, encryption
> at rest for RDS/S3/EC2 volumes, SSL enforcement, DenyNonHTTPS bucket policy,
> security group rules per tenant, NACL rules with explanation of why ephemeral
> ports are needed, and how cross-tenant traffic is prevented at two independent
> layers. Include a table for encryption coverage and a table for NACL rules.
> Reference actual file locations throughout.

**Key Output Taken:**
Full Task 3 README section with tables and file references.

**What I Changed:**
- Added the two-layer enforcement explanation more explicitly - IAM layer and
  Security Group layer are independent. AI's draft mentioned both but didn't
  emphasise that they are independent boundaries. This is the key architectural
  point the assignment is looking for.

---

## Task 4 - CI/CD Pipeline

---

### Prompt 4.1 - Pipeline Structure Decision

**Prompt:**
> The assignment says multiple teams should be able to independently trigger
> deployments without interfering with each other. I have three tenant services -
> companies, bureaus, employees. Should I use one workflow file with conditional
> logic per tenant, or three separate workflow files? Give me the trade-offs before
> I decide.

**Key Output Taken:**
Trade-off analysis - one file with conditions vs three separate files.

**What I Decided:**
Three separate workflow files. With one file and conditions, a syntax error in
the shared workflow breaks all three deployments simultaneously. Separate files
mean the companies team can edit their pipeline without risk of affecting bureaus
or employees. Path filters on each workflow file ensure a push that only touches
companies code never triggers a bureaus deployment.

---

### Prompt 4.2 - Dockerfile and Application

**Prompt:**
> Write a minimal but production-appropriate Dockerfile for a Python Flask
> hello-world service. Use python:3.11-slim, create a non-root user, copy
> requirements before source code for better layer caching, expose port 8080,
> and use gunicorn instead of the Flask dev server. The app should have a /health
> endpoint returning service name and environment from environment variables.

**Key Output Taken:**
Dockerfile with non-root user, layer-optimised COPY order, gunicorn CMD,
and Flask app with /health endpoint.

**What I Changed:**
- Specified non-root user explicitly in the prompt - security baseline for
  any production container. Running as root inside a container means a container
  escape gives the attacker root on the host.
- Specified gunicorn over Flask dev server - Flask's built-in server is
  single-threaded and not suitable for production. AI would have used it by
  default without this instruction.

---

### Prompt 4.3 - GitHub Actions Workflows

**Prompt:**
> Write three GitHub Actions workflow files - one each for companies, bureaus,
> and employees. Each should: trigger on push to main only when files in its
> own path change, build and test the Docker image, push to GitHub Container
> Registry (not ECR - free tier), and deploy to the correct EC2 instance via
> SSM send-command. All secrets via GitHub Secrets - nothing hardcoded in YAML.
> Use github.sha as the image tag for traceability.

**Key Output Taken:**
Three workflow files with path filters, GHCR push, and SSM deployment.

**What I Changed/Added:**
- Used GHCR instead of ECR - AI's first suggestion was ECR. The assignment
  explicitly says no paid container registry. GHCR is free with a GitHub account
  and works identically for this use case.
- Added `ok_actions` to SNS alongside `alarm_actions` - AI only added alarm
  notifications. Recovery notifications are equally important so the team knows
  when an incident has resolved without manually checking CloudWatch.

---

### Prompt 4.4 - Deployment Script

**Prompt:**
> Write a bash deployment script that runs on EC2 via SSM. It should accept
> service name, environment, and image tag as arguments, stop and remove the
> existing container, pull the new image from GHCR, run it with environment
> variables injected, and do a health check after deployment with automatic
> rollback if the health check fails. Use set -e so the script exits on any error.

**Key Output Taken:**
`deploy.sh` with argument validation, container lifecycle management, health
check, and rollback on failure.

**What I Changed:**
- Added argument validation at the top - AI's draft assumed arguments were always
  present. Missing arguments would cause confusing errors mid-script. Explicit
  validation fails fast with a clear usage message.
- Added `|| true` to the docker stop and rm commands - if no container is running
  on first deploy, these commands would fail and exit the script. `|| true`
  makes them idempotent.

---

## Task 5 - Monitoring & Incident Readiness

---

### Prompt 5.1 - Monitoring Planning

**Prompt:**
> I'm setting up CloudWatch monitoring for a multi-tenant UK payroll platform.
> Three EC2 t3.micro instances and one RDS PostgreSQL db.t3.micro. Before writing
> Terraform, recommend what to monitor and why - don't write code yet.

**Key Output Taken:**
Recommendations: EC2 CPU, RDS connections, RDS CPU, RDS storage, log groups
per service.

**What I Added Beyond AI Recommendation:**
- EventBridge rule watching for RDS-EVENT-0088 specifically - this is the exact
  AWS event that fires when publicly_accessible is changed on an RDS instance.
  The runbook scenario is specifically about this incident so the detection
  mechanism should match it precisely. AI didn't suggest this.
- RDS free storage alarm - AI didn't suggest this. A full RDS disk causes the
  database to stop accepting writes, which on a payroll platform means payroll
  runs fail silently. 5GB threshold gives enough warning to act.

---

### Prompt 5.2 - CloudWatch Terraform

**Prompt:**
> Write the Terraform for monitoring/cloudwatch.tf. Include: SNS topic with email
> subscription, separate CloudWatch log groups per tenant service with 30 day
> retention and 90 days for infrastructure logs, CPU alarms for all three EC2
> instances at 80% threshold over 2 evaluation periods, RDS connection count alarm
> at 50 connections, RDS CPU alarm at 80%, RDS free storage alarm at 5GB, and an
> EventBridge rule that fires on RDS-EVENT-0088. Wire all alarms to the SNS topic.

**Key Output Taken:**
Full `monitoring/cloudwatch.tf` with all alarms, log groups, SNS, and
EventBridge rule.

**What I Changed:**
- Set infrastructure log retention to 90 days - AI defaulted to 30 days for
  everything. Post-incident forensics on a payroll platform may need to look back
  further than 30 days, especially for compliance investigations.
- Added `ok_actions` to all alarms pointing to SNS - AI only added `alarm_actions`.
  Without ok_actions the team never gets notified when an incident resolves and
  has to manually check CloudWatch to confirm recovery.

---

### Prompt 5.3 - Incident Response Runbook

**Prompt:**
> Write an incident response runbook in markdown for this scenario: the RDS database
> is accidentally made publicly accessible. Cover detection with specific AWS CLI
> commands, immediate containment, investigation steps to find who made the change
> via CloudTrail and whether unauthorized connections occurred, recovery steps,
> and a post-incident actions table. Include ICO notification within 72 hours -
> this is a UK GDPR legal requirement. Keep it to one page.

**Key Output Taken:**
Full runbook covering detection, containment, investigation, recovery, and
post-incident actions.

**What I Changed/Added:**
- Added ICO 72-hour notification to the post-incident table - AI's first draft
  omitted this entirely. UK GDPR Article 33 requires notifying the ICO within
  72 hours of becoming aware of a breach. Missing this would be a serious
  compliance gap for a regulated payroll platform.
- Added credential rotation as part of immediate containment - AI's draft
  focused on closing the exposure but didn't include rotating the master password.
  Even if no breach is confirmed, rotating credentials after an exposure is
  standard security practice.

---

## Task 6 - UK Compliance Considerations



### Prompt 6.1 - Learning the Compliance Landscape

**Prompt:**
> I'm building a UK payroll platform that stores employee PII, bank account
> details, and national insurance numbers on AWS. Before I write anything,
> help me understand what UK GDPR obligations I need to address. What are
> the rules around data residency, right to erasure, and encryption for
> this kind of platform? Don't give me AWS implementation yet - I want to
> understand the legal landscape first.

**Key Output Taken:**
- UK GDPR Article 17 covers right to erasure - individuals can request
  permanent deletion of their personal data
- Data must stay within UK/EU region to comply with data transfer restrictions
- Encryption at rest and in transit is expected for sensitive PII
- AWS Config can be used to monitor compliance posture
- Detective controls like Config alert after a violation occurs

**What I Noted / What I Already Knew:**
- AI explained erasure as straightforward deletion. I already knew this
  conflicts with HMRC requirements - UK tax law requires payroll records
  to be retained for a minimum of 3 years. Blanket deletion would violate
  tax law. The correct approach is anonymisation - strip the PII linkage
  but retain the payroll record. AI didn't flag this conflict at all.
- AI mentioned AWS Config rules as the way to enforce data residency. I
  understood Config is a detective control - it tells you after something
  wrong has already happened. I wanted to know if a preventive control
  existed that couldn't be overridden by an account admin.

---

### Prompt 6.2 - Filling the Gaps

**Prompt:**
> Two follow up questions. First - if HMRC requires payroll records for
> 3 years minimum, does that conflict with UK GDPR right to erasure? How
> should a payroll platform handle an erasure request where legal retention
> applies? Second - is there an AWS control stronger than Config rules for
> data residency that prevents resources being created outside eu-west-2
> at the organisation level, not just alerting after the fact?

**Key Output Taken:**
- UK GDPR Article 17(3) explicitly allows retention where necessary for
  legal obligation - HMRC 3 year retention is a valid exemption
- Correct approach is anonymisation - retain the record, remove the PII
  that links it to the individual
- Service Control Policies (SCPs) at AWS Organisation level can deny any
  API call where `aws:RequestedRegion` is not eu-west-2 - this is a
  preventive control that cannot be overridden by account admins

**What I Learned:**
- Article 17(3) exemption was the specific legal basis I needed -
  now I could write the erasure section accurately
- SCPs were exactly what I was looking for - preventive not detective,
  and cannot be bypassed. Much stronger guarantee than Config rules.

---

### Prompt 6.3 - Writing the README Section

**Prompt:**
> Now write the Task 6 README section covering all three questions:
> AWS-native controls for UK GDPR compliance referencing actual Terraform
> files already written, data residency enforcement in eu-west-2 including
> both Config rules as detective controls and SCPs as preventive controls,
> and right to erasure across database, S3 versioning, Secrets Manager,
> and CloudWatch logs. For erasure requests where HMRC 3 year retention
> applies, use anonymisation not deletion and cite Article 17(3) as the
> legal basis. Be specific - no vague language like "several years",
> state 3 years explicitly.

**Key Output Taken:**
Full Task 6 README section with all three questions answered.

**What I Changed:**
- AI wrote "several years" for HMRC retention period in one place -
  changed to 3 years. Vague language in compliance documentation is
  not acceptable for a regulated platform.
- Verified all Terraform file references matched actual module names
  and resource configurations already written.
- Added a note that CloudWatch logs may contain PII in stack traces
  or error messages - structured logging should use anonymised IDs
  only. AI's draft didn't mention this edge case.