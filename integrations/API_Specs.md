# LSIHEP External Integration Specifications

## Overview
This document outlines the technical specifications for integrating LSIHEP with external government systems and third-party services.

---

## 1. Identity & Verification Integrations

### 1.1 LASRRA (Lagos State Residents Registration Agency)

**Purpose:** Identity verification and residency validation

**Integration Method:** REST API

**Authentication:** OAuth 2.0 / API Key

**Endpoints:**

**POST** `/api/v1/lasrra/verify`
```json
Request:
{
  "nin_number": "string",
  "surname": "string",
  "first_name": "string",
  "middle_name": "string (optional)",
  "dob": "YYYY-MM-DD",
  "phone": "string"
}

Response:
{
  "status": "success|failed",
  "verification_id": "string",
  "data": {
    "full_name": "string",
    "residency_status": "verified|not_found",
    "lga_of_residence": "string",
    "registration_date": "ISO8601",
    "identity_score": "number (0-100)"
  },
  "timestamp": "ISO8601"
}
Error Handling:
400: Invalid request parameters
401: Authentication failed
404: Record not found
429: Rate limit exceeded
500: LASRRA system error
Retry Policy: 3 attempts with exponential backoff (1s, 2s, 4s)
1.2 NIMC/NIN Validation
Purpose: National identity verification
Integration Method: REST API
Authentication: API Key + IP Whitelisting
Endpoints:
POST /api/v1/nin/validate
Request:
{
  "nin": "11-digit number",
  "first_name": "string",
  "last_name": "string",
  "dob": "YYYY-MM-DD"
}

Response:
{
  "status": "match|mismatch|not_found",
  "verification_ref": "string",
  "details": {
    "name_match": "boolean",
    "dob_match": "boolean",
    "biometric_status": "enrolled|pending",
    "card_status": "issued|pending"
  }
}
Rate Limits: 100 requests/minute
1.3 BVN Verification
Purpose: Bank verification for financial transactions
Integration Method: Secure API (NIBSS)
Endpoints:
POST /api/v1/bvn/verify
Request:
{
  "bvn": "11-digit number",
  "account_number": "10-digit number",
  "bank_code": "string"
}

Response:
{
  "status": "success|failed",
  "data": {
    "name": "string",
    "dob": "YYYY-MM-DD",
    "phone": "string",
    "account_status": "active|dormant"
  }
}
Compliance: NDPR-compliant data handling
2. Payment & Treasury Integrations
2.1 REMITA Payment Gateway
Purpose: Payment processing and treasury reconciliation
Integration Method: REST API + Webhooks
Authentication: API Key + Merchant ID
Endpoints:
POST /api/v1/remita/payment/initiate
Request:
{
  "merchant_id": "string",
  "invoice_number": "string",
  "amount": "decimal",
  "payer_name": "string",
  "payer_email": "string",
  "payer_phone": "string",
  "description": "string",
  "callback_url": "string"
}

Response:
{
  "status": "success",
  "rrr": "12-digit Remita Retrieval Reference",
  "payment_url": "string",
  "expiry": "ISO8601"
}
Webhook: POST /api/webhooks/remita/payment-status
Payload:
{
  "rrr": "string",
  "status": "success|failed|pending",
  "amount": "decimal",
  "payment_date": "ISO8601",
  "transaction_ref": "string",
  "bank_ref": "string"
}
Reconciliation:
Daily settlement reports via SFTP
Real-time payment status via webhook
Mismatch alerts for manual review
2.2 State Treasury System
Purpose: Payment reconciliation and revenue tracking
Integration Method: REST API / SFTP Batch Files
Authentication: Certificate-based authentication
Endpoints:
GET /api/v1/treasury/reconciliation/{date}
Response:
{
  "date": "YYYY-MM-DD",
  "total_collections": "decimal",
  "transactions": [
    {
      "treasury_ref": "string",
      "amount": "decimal",
      "payment_channel": "string",
      "settlement_status": "settled|pending",
      "settlement_date": "ISO8601"
    }
  ]
}
Batch File Format (CSV):
Date,RRR,Amount,Channel,TreasuryRef,Status
2026-03-01,123456789012,50000.00,REMITA,TSR-2026-001,Settled
Reconciliation Workflow:
Portal payments collected throughout day
Treasury receives settlement from banks (T+1)
System compares portal records vs treasury records
Mismatches flagged for review
90-day window for resolution before allocation clearance
2.3 NIBSS (Nigeria Inter-Bank Settlement System)
Purpose: Direct bank transfers and USSD payments
Integration Method: ISO 8583 / API
Features:
Real-time fund transfers
Account name enquiry
BVN validation
Transaction status enquiry
3. Property & Legal Integrations
3.1 Lands Bureau
Purpose: Property and title verification
Integration Method: REST API
Authentication: API Key + Role-based access
Endpoints:
GET /api/v1/lands/property/{property_id}
Response:
{
  "property_id": "string",
  "title_number": "string",
  "title_type": "CofO|Deed|Other",
  "owner_name": "string",
  "property_address": "string",
  "encumbrances": [
    {
      "type": "mortgage|lien|court_order",
      "description": "string",
      "date_registered": "ISO8601"
    }
  ],
  "verification_status": "clear|encumbered|disputed",
  "last_verified": "ISO8601"
}
POST /api/v1/lands/title/verify
Request:
{
  "title_number": "string",
  "applicant_nin": "string"
}

Response:
{
  "verification_ref": "string",
  "status": "verified|not_found|disputed",
  "cofo_number": "string",
  "issue_date": "ISO8601",
  "registered_owner": "string"
}
3.2 E-Signature Provider
Purpose: Digital signing of leases, offers, and legal documents
Options: DocuSign, SignRequest, or local Nigerian provider
Integration Method: REST API
Workflow:
Generate PDF document
Send to e-signature API with signer details
Recipient receives email/SMS to sign
Webhook notifies system when signed
Signed document stored in vault
Endpoints:
POST /api/v1/esign/send
Request:
{
  "document_type": "lease|offer|notice",
  "document_id": "string",
  "signers": [
    {
      "name": "string",
      "email": "string",
      "phone": "string",
      "role": "tenant|landlord|witness"
    }
  ],
  "callback_url": "string"
}
4. Communication Integrations
4.1 SMS Gateway
Purpose: SMS notifications for alerts, OTP, reminders
Providers: Twilio, Termii, or local Nigerian SMS provider
Integration Method: REST API
Endpoints:
POST /api/v1/sms/send
Request:
{
  "to": "+234XXXXXXXXXX",
  "message": "string",
  "sender_id": "LSIHEP",
  "priority": "normal|urgent"
}

Response:
{
  "message_id": "string",
  "status": "sent|queued|failed",
  "cost": "decimal"
}
Use Cases:
OTP for login/MFA
Payment reminders
Maintenance updates
Allocation notifications
Emergency alerts
4.2 Email Service
Purpose: Email notifications and document delivery
Providers: SendGrid, AWS SES, or Microsoft 365
Integration Method: SMTP / REST API
Endpoints:
POST /api/v1/email/send
Request:
{
  "to": ["email1@example.com"],
  "cc": ["email2@example.com"],
  "subject": "string",
  "body_html": "string",
  "attachments": [
    {
      "filename": "string",
      "content_base64": "string",
      "content_type": "application/pdf"
    }
  ]
}
Templates:
Welcome email
Application status updates
Rent invoices
Maintenance confirmations
Legal notices
4.3 Push Notifications (Mobile)
Purpose: Real-time mobile app notifications
Provider: Firebase Cloud Messaging (FCM)
Integration Method: FCM API
Payload:
{
  "to": "device_token",
  "notification": {
    "title": "string",
    "body": "string",
    "icon": "string",
    "click_action": "string"
  },
  "data": {
    "type": "maintenance_update|payment_due|allocation_notice",
    "entity_id": "string"
  }
}
5. Integration Security
5.1 Authentication Methods
OAuth 2.0: For user-delegated access
API Keys: For server-to-server communication
Mutual TLS: For high-security integrations (Treasury)
JWT Tokens: For internal microservices
5.2 Data Encryption
In Transit: TLS 1.3 minimum
At Rest: AES-256 for stored credentials
API Keys: Encrypted in database, rotated every 90 days
5.3 Rate Limiting
External APIs: Respect provider limits (typically 100-1000 req/min)
Internal APIs: 1000 req/min per IP
Webhooks: Retry with exponential backoff
5.4 Error Handling
Circuit Breaker: Prevent cascade failures
Retry Logic: 3 attempts with backoff
Fallback: Queue for later processing if API unavailable
Alerting: Notify admins on repeated failures
6. Integration Monitoring
6.1 Health Checks
Endpoint: GET /api/health/integrations
Checks:
LASRRA API status
NIMC API status
REMITA API status
Treasury connection
SMS gateway status
Email service status
6.2 Metrics to Track
API response time (p95, p99)
Success/failure rate per integration
Queue depth for async jobs
Webhook delivery success rate
Reconciliation mismatch count
6.3 Logging
All API requests logged (request/response)
PII data masked in logs
Audit trail for sensitive operations
Log retention: 7 years
7. Data Mapping & Transformation
7.1 Field Mapping Examples
Citizen Profile → LASRRA:
LSIHEP Field          → LASRRA Field
profile.nin_number    → nin
profile.first_name    → firstName
profile.last_name     → surname
profile.dob           → dateOfBirth
profile.phone         → phoneNumber
Payment → REMITA:
LSIHEP Field          → REMITA Field
invoice.invoice_id    → merchantInvoiceNumber
invoice.amount        → amount
profile.email         → payerEmail
profile.phone         → payerPhone
7.2 Data Validation Rules
NIN: Exactly 11 digits
BVN: Exactly 11 digits
Phone: +234XXXXXXXXXX format
Email: RFC 5322 compliant
Amount: Decimal with 2 places
8. Testing & Sandboxing
8.1 Sandbox Environments
Each integration provider should offer:
Test API endpoints
Mock responses
Test credentials
No production data
8.2 Test Scenarios
Successful verification
Failed verification
Network timeout
Invalid credentials
Rate limit exceeded
Webhook delivery
8.3 Integration Testing
Automated tests for each integration
Contract testing (OpenAPI/Swagger)
Performance testing (load tests)
Security testing (penetration tests)
9. Implementation Timeline
Phase
Integration
Priority
Estimated Effort
MVP
SMS Gateway
High
2 weeks
MVP
Email Service
High
1 week
Phase 2
REMITA
High
3 weeks
Phase 2
LASRRA
High
3 weeks
Phase 2
NIMC/NIN
High
2 weeks
Phase 3
Treasury System
High
4 weeks
Phase 3
Lands Bureau
Medium
3 weeks
Phase 3
E-Signature
Medium
2 weeks
10. Contact Information
For Integration Support:
LASRRA: api-support@lasrra.lagosstate.gov.ng
NIMC: integration@nimc.gov.ng
REMITA: support@remita.net
State Treasury: ict@treasury.lagosstate.gov.ng
PCIS Technical Team: tech@pcis-ltd.com
Last Updated: March 2026
Prepared by: PCIS Limited Integration Team
