# LSIHP — API Contracts Specification
**Version:** 1.0 | **Date:** April 2026  
**Prepared by:** PCIS — Prime Connection Integrated Solutions Ltd  
**Classification:** Confidential — Government Use  
**Base URL:** `https://api.lsihp.lagosstate.gov.ng/api/v1`

---

## Table of Contents
1. [API Standards](#1-api-standards)
2. [Authentication](#2-authentication)
3. [Module A — E-KYC (LASRRA Integration)](#3-module-a--e-kyc-lasrra-integration)
4. [Module B — Merit-Based Allocation](#4-module-b--merit-based-allocation)
5. [Module C — E-Deeds & Document Generation](#5-module-c--e-deeds--document-generation)
6. [Module D — Treasury Payment Integration](#6-module-d--treasury-payment-integration)
7. [Error Handling](#7-error-handling)
8. [Webhook Security](#8-webhook-security)

---

## 1. API Standards

| Standard | Specification |
|----------|--------------|
| Protocol | HTTPS (TLS 1.3 minimum) — all endpoints |
| Data Format | JSON (application/json) — all requests and responses |
| Authentication | OAuth 2.0 + JWT Bearer Token (RS256 signed) |
| Authorisation | Role-Based Access Control (RBAC) |
| Rate Limiting | 500 requests/minute per authenticated client |
| Versioning | URL-based: `/api/v1/` — breaking changes increment version |
| Idempotency | POST endpoints accept `Idempotency-Key` header |
| Error Format | RFC 7807 Problem Details |
| Pagination | Cursor-based: `{ data, next_cursor, has_more, total_count }` |
| Audit Header | `X-Request-ID` required on all calls — logged in AUDIT_LOG |
| Timezone | All timestamps in ISO 8601 with WAT offset (`+01:00`) |

### RBAC Roles

| Role | Description | Access Level |
|------|-------------|-------------|
| `applicant` | Registered citizen | Own records only |
| `reviewer` | Ministry staff reviewer | Read all; approve/reject |
| `admin` | Ministry administrator | Full access |
| `system` | Internal service account | System-initiated actions |
| `treasury` | Treasury API service | Payment endpoints only |
| `lasrra` | LASRRA API service | KYC endpoints only |

---

## 2. Authentication

### Obtain Token
**POST** `/auth/token`

**Request:**
```json
{
  "grant_type": "client_credentials",
  "client_id": "your_client_id",
  "client_secret": "your_client_secret",
  "scope": "applicant:read application:write"
}
```

**Response (HTTP 200):**
```json
{
  "access_token": "eyJhbGciOiJSUzI1NiJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "applicant:read application:write"
}
```

**Usage:**
```
Authorization: Bearer eyJhbGciOiJSUzI1NiJ9...
X-Request-ID: uuid-v4-request-id
```

---

## 3. Module A — E-KYC (LASRRA Integration)

### 3.1 Verify Applicant Identity
Triggers real-time identity verification against LASRRA, NIMC, and BVN databases.  
Eliminates ghost applicants at point of registration.

**POST** `/kyc/verify`  
**Roles:** `system`, `admin`  
**Idempotency:** Supported

**Request:**
```json
{
  "lasrra_id":     "LAS-2024-0012345",
  "nin":           "12345678901",
  "bvn":           "12345678901",
  "date_of_birth": "1985-03-15",
  "applicant_id":  "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
}
```

**Response — Success (HTTP 200):**
```json
{
  "status":           "VERIFIED",
  "applicant_id":     "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "lasrra_match":     true,
  "nin_match":        true,
  "bvn_match":        true,
  "is_ghost":         false,
  "kyc_verified_at":  "2026-04-01T09:15:00+01:00",
  "blockchain_hash":  "0xabc123def456...",
  "message":          "Identity verified successfully"
}
```

**Response — Failed (HTTP 422):**
```json
{
  "type":       "https://api.lsihp.lagosstate.gov.ng/errors/kyc-mismatch",
  "title":      "KYC Identity Mismatch",
  "status":     422,
  "detail":     "LASRRA record does not match provided NIN",
  "instance":   "/kyc/verify",
  "error_code": "KYC_IDENTITY_MISMATCH",
  "flagged":    true
}
```

**Response — Ghost Applicant Detected (HTTP 409):**
```json
{
  "type":       "https://api.lsihp.lagosstate.gov.ng/errors/ghost-detected",
  "title":      "Ghost Applicant Detected",
  "status":     409,
  "detail":     "Duplicate identity detected across multiple application attempts",
  "error_code": "GHOST_APPLICANT_DETECTED",
  "flagged":    true
}
```

### 3.2 Get KYC Status
**GET** `/kyc/status/{applicant_id}`  
**Roles:** `applicant` (own only), `reviewer`, `admin`

**Response (HTTP 200):**
```json
{
  "applicant_id":    "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "kyc_status":      "Verified",
  "kyc_verified_at": "2026-04-01T09:15:00+01:00",
  "blockchain_hash": "0xabc123def456..."
}
```

---

## 4. Module B — Merit-Based Allocation

### 4.1 Compute Merit Score
Runs the allocation algorithm against an application. System-generated — no external input required. All data is sourced from verified internal and integrated databases.

**POST** `/applications/{application_id}/score`  
**Roles:** `system`, `admin`

**Response (HTTP 200):**
```json
{
  "application_id":  "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "scheme_id":       "c3d4e5f6-a7b8-9012-cdef-123456789012",
  "scoring_criteria": {
    "first_time_owner": { "verified": true,  "points": 30.00 },
    "civil_servant":    { "verified": true,  "points": 20.00 },
    "income_eligible":  { "verified": true,  "points": 20.00 },
    "payment_date":     { "rank": 45,        "points": 12.00 },
    "lagos_residency":  { "years": 8,        "points": 10.00 },
    "age_bracket":      { "bracket": "35-50","points": 3.00  }
  },
  "total_merit_score": 95.00,
  "priority_band":     "Band_A",
  "scored_at":         "2026-04-15T10:00:00+01:00",
  "scored_by":         "system_algorithm_v2.1"
}
```

### 4.2 Get Ranked Applicants for a Scheme
Returns merit-ranked list of applicants for Ministry review.

**GET** `/schemes/{scheme_id}/ranked-applicants`  
**Roles:** `reviewer`, `admin`  
**Query Params:** `?priority_band=Band_A&limit=50&cursor=next_cursor_value`

**Response (HTTP 200):**
```json
{
  "scheme_id":    "c3d4e5f6-a7b8-9012-cdef-123456789012",
  "total_count":  1247,
  "has_more":     true,
  "next_cursor":  "eyJsYXN0X2lkIjoiYWJjMTIzIn0=",
  "data": [
    {
      "application_id":  "...",
      "application_ref": "LSH-2026-00045",
      "applicant_name":  "Adunola Fashola",
      "merit_score":     98.50,
      "priority_band":   "Band_A",
      "status":          "Approved"
    }
  ]
}
```

### 4.3 Confirm Allocation
Triggers unit assignment for a ranked applicant. System-initiated or manual override.

**POST** `/allocations`  
**Roles:** `system`, `admin`  
**Idempotency:** Supported

**Request:**
```json
{
  "application_id": "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "unit_id":        "d4e5f6a7-b8c9-0123-defa-234567890123",
  "allocated_by":   "System"
}
```

**Response (HTTP 201):**
```json
{
  "allocation_id":         "e5f6a7b8-c9d0-1234-efab-345678901234",
  "application_id":        "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "unit_id":               "d4e5f6a7-b8c9-0123-defa-234567890123",
  "allocation_date":       "2026-04-15T10:05:00+01:00",
  "acceptance_deadline":   "2026-04-29",
  "acceptance_status":     "Pending",
  "blockchain_hash":       "0xdef456abc789...",
  "next_step":             "DOCUMENT_GENERATION"
}
```

---

## 5. Module C — E-Deeds & Document Generation

### 5.1 Generate Document
Automatically generates allocation letters, C-of-O, and Sub-lease Deeds with digital signatures.

**POST** `/documents/generate`  
**Roles:** `system`, `admin`  
**Idempotency:** Supported

**Request — Allocation Letter:**
```json
{
  "document_type":   "Allocation_Letter",
  "allocation_id":   "e5f6a7b8-c9d0-1234-efab-345678901234",
  "application_id":  "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "applicant_id":    "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "unit_id":         "d4e5f6a7-b8c9-0123-defa-234567890123",
  "scheme_name":     "LASG Affordable Housing Scheme Phase IV",
  "generated_by":    "System",
  "sign_with_key":   "ministry_signing_key_prod"
}
```

**Response (HTTP 201):**
```json
{
  "document_id":       "f6a7b8c9-d0e1-2345-fabc-456789012345",
  "document_ref":      "LSH-DOC-2026-00891",
  "document_type":     "Allocation_Letter",
  "status":            "Issued",
  "storage_url":       "https://docs.lsihp.lagosstate.gov.ng/secure/LSH-DOC-2026-00891?sig=...",
  "digital_signature": "sha256_sig_abc123...",
  "blockchain_hash":   "0x789abc123def...",
  "generated_at":      "2026-04-15T10:06:00+01:00",
  "issued_at":         "2026-04-15T10:06:00+01:00"
}
```

### 5.2 Get Document
**GET** `/documents/{document_id}`  
**Roles:** `applicant` (own only), `reviewer`, `admin`

**Response (HTTP 200):**
```json
{
  "document_id":    "f6a7b8c9-d0e1-2345-fabc-456789012345",
  "document_ref":   "LSH-DOC-2026-00891",
  "document_type":  "Allocation_Letter",
  "status":         "Issued",
  "storage_url":    "https://docs.lsihp.lagosstate.gov.ng/secure/...",
  "issued_at":      "2026-04-15T10:06:00+01:00",
  "blockchain_hash":"0x789abc123def...",
  "verified":       true
}
```

### 5.3 Verify Document Authenticity
Public endpoint — enables any party to verify a document against the blockchain.

**GET** `/documents/verify/{document_ref}`  
**Roles:** Public (no authentication required)

**Response (HTTP 200):**
```json
{
  "document_ref":    "LSH-DOC-2026-00891",
  "document_type":   "Allocation_Letter",
  "issued_at":       "2026-04-15T10:06:00+01:00",
  "blockchain_hash": "0x789abc123def...",
  "chain_verified":  true,
  "tampered":        false,
  "message":         "Document is authentic and unmodified"
}
```

---

## 6. Module D — Treasury Payment Integration

### 6.1 Inbound — Treasury Payment Confirmation Webhook
Received from the Lagos State Treasury system (REMITA). Confirms payment and automatically triggers the next workflow step without human intervention.

**POST** `/payments/confirm`  
**Auth:** HMAC-SHA256 signature verification (see Section 8)  
**Roles:** `treasury` service account only

**Inbound Payload (from Treasury):**
```json
{
  "payment_ref":        "REMITA-2026-TXN-00045678",
  "application_id":     "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "amount":             250000.00,
  "currency":           "NGN",
  "payment_channel":    "REMITA",
  "payment_status":     "CONFIRMED",
  "treasury_confirmed": true,
  "confirmed_at":       "2026-04-01T08:47:22+01:00",
  "treasury_ref":       "LSTSY-2026-00456",
  "signature":          "hmac_sha256_treasury_key_abc123..."
}
```

**LSIHP Response (HTTP 200):**
```json
{
  "payment_id":          "a7b8c9d0-e1f2-3456-abcd-567890123456",
  "payment_ref":         "REMITA-2026-TXN-00045678",
  "status":              "CONFIRMED",
  "treasury_confirmed":  true,
  "workflow_triggered":  true,
  "next_workflow_step":  "MERIT_SCORING",
  "blockchain_hash":     "0x123abc456def...",
  "confirmed_at":        "2026-04-01T08:47:22+01:00",
  "message":             "Payment confirmed. Merit scoring initiated."
}
```

### 6.2 Get Payment Status
**GET** `/payments/{payment_id}`  
**Roles:** `applicant` (own only), `reviewer`, `admin`

**Response (HTTP 200):**
```json
{
  "payment_id":         "a7b8c9d0-e1f2-3456-abcd-567890123456",
  "application_id":     "b2c3d4e5-f6a7-8901-bcde-f12345678901",
  "payment_ref":        "REMITA-2026-TXN-00045678",
  "amount":             250000.00,
  "currency":           "NGN",
  "payment_status":     "Confirmed",
  "treasury_confirmed": true,
  "workflow_triggered": true,
  "receipt_url":        "https://receipts.lsihp.lagosstate.gov.ng/...",
  "blockchain_hash":    "0x123abc456def..."
}
```

### 6.3 Get Payment History for Application
**GET** `/applications/{application_id}/payments`  
**Roles:** `applicant` (own only), `reviewer`, `admin`

---

## 7. Error Handling

All errors follow RFC 7807 Problem Details format.

### Standard Error Response
```json
{
  "type":     "https://api.lsihp.lagosstate.gov.ng/errors/{error-slug}",
  "title":    "Human-readable error title",
  "status":   400,
  "detail":   "Detailed explanation of what went wrong",
  "instance": "/api/v1/path/that/failed",
  "error_code": "MACHINE_READABLE_CODE"
}
```

### HTTP Status Codes

| Code | Meaning | Common Cause |
|------|---------|-------------|
| 200 | OK | Successful GET or action |
| 201 | Created | Resource successfully created |
| 400 | Bad Request | Malformed JSON or missing required fields |
| 401 | Unauthorized | Invalid or expired JWT token |
| 403 | Forbidden | Insufficient role permissions |
| 404 | Not Found | Resource does not exist |
| 409 | Conflict | Duplicate record or state conflict |
| 422 | Unprocessable | Validation failure (e.g. KYC mismatch) |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Unexpected system error |
| 503 | Service Unavailable | Downstream service (LASRRA, Treasury) unavailable |

---

## 8. Webhook Security

All inbound webhooks from Treasury and LASRRA must be verified using HMAC-SHA256.

### Verification Process
```
1. Extract X-LSIHP-Signature header from inbound request
2. Compute HMAC-SHA256 of raw request body using shared secret
3. Compare computed signature with header value (constant-time comparison)
4. Reject request if signatures do not match (return HTTP 401)
5. Check timestamp in payload — reject if older than 5 minutes (replay protection)
```

### Example Verification (Node.js)
```javascript
const crypto = require('crypto');

function verifyWebhookSignature(rawBody, signature, secret) {
  const computed = crypto
    .createHmac('sha256', secret)
    .update(rawBody)
    .digest('hex');
  return crypto.timingSafeEqual(
    Buffer.from(computed),
    Buffer.from(signature)
  );
}
```

---

*PCIS — Prime Connection Integrated Solutions Ltd | www.pcis-ltd.com*  
*© 2026 All Rights Reserved | Confidential — Government Use*
