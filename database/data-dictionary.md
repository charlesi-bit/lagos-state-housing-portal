# LSIHP — Data Dictionary
**Version:** 1.0 | **Date:** April 2026  
**Prepared by:** PCIS — Prime Connection Integrated Solutions Ltd  
**Classification:** Confidential — Government Use

---

## Overview

This data dictionary provides the authoritative reference for all tables, fields, data types, and business rules in the Lagos State Integrated Housing Portal (LSIHP) database. It should be read alongside `schema.sql` and `erd.md`.

**Database Engine:** PostgreSQL 15+  
**Blockchain Layer:** Hyperledger Fabric (permissioned)  
**Timezone:** Africa/Lagos (WAT, UTC+1)  
**UUID Version:** UUID v4 (all primary keys)

---

## Table Index

| Table | Description |
|-------|-------------|
| [applicant](#applicant) | Registered applicants and KYC status |
| [housing_scheme](#housing_scheme) | Housing schemes offered by the Ministry |
| [housing_unit](#housing_unit) | Individual units within a scheme |
| [application](#application) | Submitted housing applications |
| [payment](#payment) | Payment transactions |
| [allocation](#allocation) | Confirmed housing allocations |
| [document](#document) | E-Deeds, letters, certificates |
| [audit_log](#audit_log) | Immutable system activity log |
| [scoring_config](#scoring_config) | Merit score weighting configuration |

---

## applicant

Stores every citizen who registers on the LSIHP portal. All PII fields are encrypted at rest using AES-256.

| Field | Type | Nullable | Description | Business Rule |
|-------|------|----------|-------------|---------------|
| `applicant_id` | UUID | No | Primary key | Auto-generated UUID v4 |
| `lasrra_id` | VARCHAR(20) | No | Lagos State Resident Registration number | Must be unique; verified against LASRRA API |
| `nin` | VARCHAR(11) | No | National Identification Number | Must be unique; verified against NIMC |
| `bvn` | VARCHAR(11) | No | Bank Verification Number | Must be unique; one BVN per applicant |
| `first_name` | VARCHAR(100) | No | Legal first name | As per LASRRA record |
| `last_name` | VARCHAR(100) | No | Legal surname | As per LASRRA record |
| `middle_name` | VARCHAR(100) | Yes | Middle name | Optional |
| `date_of_birth` | DATE | No | Date of birth | Used for age bracket scoring |
| `gender` | VARCHAR(10) | Yes | Gender identity | Enum: Male, Female, Other |
| `email` | VARCHAR(255) | No | Primary email | Unique; used for all communications |
| `phone_primary` | VARCHAR(20) | No | Primary mobile number | Must include country code |
| `phone_secondary` | VARCHAR(20) | Yes | Secondary contact | Optional |
| `employment_type` | VARCHAR(30) | Yes | Employment category | Enum: Civil_Servant, Private, Self_Employed, Other |
| `civil_service_grade` | VARCHAR(10) | Yes | Grade level | Only populated if Civil_Servant |
| `mdas_code` | VARCHAR(20) | Yes | Ministry/Dept/Agency code | Used for IPPIS cross-check |
| `is_first_time_owner` | BOOLEAN | No | No prior property ownership | Self-declared; cross-checked with Lands Bureau |
| `kyc_status` | VARCHAR(20) | No | KYC verification state | Enum: Pending, Verified, Failed, Flagged |
| `kyc_verified_at` | TIMESTAMP | Yes | KYC clearance timestamp | Set by LASRRA API response |
| `blockchain_hash` | VARCHAR(256) | Yes | On-chain transaction ID | Written at KYC verification |
| `created_at` | TIMESTAMP | No | Record creation time | Auto-set |
| `updated_at` | TIMESTAMP | No | Last update time | Auto-managed by trigger |
| `deleted_at` | TIMESTAMP | Yes | Soft delete timestamp | NULL = active record |

---

## housing_scheme

Each row represents a housing scheme published by the Lagos State Ministry of Housing.

| Field | Type | Nullable | Description | Business Rule |
|-------|------|----------|-------------|---------------|
| `scheme_id` | UUID | No | Primary key | Auto-generated |
| `scheme_name` | VARCHAR(200) | No | Official scheme name | e.g. "LASG Affordable Housing Phase IV" |
| `scheme_code` | VARCHAR(20) | No | Short reference code | Unique; e.g. LSHS-TBS-001 |
| `scheme_type` | VARCHAR(30) | No | Scheme category | Enum: Social_Housing, Affordable, Middle_Income, Executive |
| `location_lga` | VARCHAR(100) | No | Local Government Area | Must be a valid Lagos LGA |
| `location_address` | TEXT | No | Full physical address | — |
| `total_units` | INTEGER | No | Total units in scheme | Must be > 0 |
| `available_units` | INTEGER | No | Units open for allocation | Decrements on each allocation |
| `unit_price_min` | DECIMAL(15,2) | No | Minimum unit price (NGN) | — |
| `unit_price_max` | DECIMAL(15,2) | No | Maximum unit price (NGN) | Must be >= unit_price_min |
| `eligibility_criteria` | JSONB | Yes | JSON rules object | Parsed by allocation algorithm |
| `allocation_open_date` | DATE | Yes | Application open date | — |
| `allocation_close_date` | DATE | Yes | Application deadline | — |
| `scheme_status` | VARCHAR(20) | No | Scheme lifecycle state | Enum: Draft, Active, Closed, Completed |

---

## housing_unit

Individual housing units within a scheme. Each unit can only be allocated to one applicant.

| Field | Type | Nullable | Description | Business Rule |
|-------|------|----------|-------------|---------------|
| `unit_id` | UUID | No | Primary key | Auto-generated |
| `scheme_id` | UUID | No | Parent scheme | FK → housing_scheme |
| `unit_number` | VARCHAR(20) | No | Unit designation | e.g. BLK-A-05; unique per scheme |
| `unit_type` | VARCHAR(20) | No | Unit category | Enum: Studio, 1-Bed, 2-Bed, 3-Bed, Duplex, Penthouse |
| `floor_level` | INTEGER | Yes | Floor number | 0 = ground floor |
| `floor_area_sqm` | DECIMAL(8,2) | Yes | Area in square metres | — |
| `price` | DECIMAL(15,2) | No | Unit price (NGN) | Must fall within scheme price range |
| `status` | VARCHAR(20) | No | Unit availability | Enum: Available, Reserved, Allocated, Occupied, Maintenance |
| `survey_plan_ref` | VARCHAR(50) | Yes | Survey plan file number | Required before C-of-O issuance |
| `c_of_o_ref` | VARCHAR(50) | Yes | Certificate of Occupancy ref | Issued after full payment |
| `blockchain_hash` | VARCHAR(256) | Yes | Unit title record hash | Written on each status change |

---

## application

Central table tracking every housing application from submission through allocation.

| Field | Type | Nullable | Description | Business Rule |
|-------|------|----------|-------------|---------------|
| `application_id` | UUID | No | Primary key | Auto-generated |
| `applicant_id` | UUID | No | Applicant reference | FK → applicant; unique per scheme |
| `scheme_id` | UUID | No | Scheme applied to | FK → housing_scheme |
| `application_ref` | VARCHAR(30) | No | Human-readable reference | Unique; format: LSH-YYYY-NNNNN |
| `status` | VARCHAR(20) | No | Application lifecycle state | Enum: Draft, Submitted, Under_Review, Approved, Rejected, Allocated, Withdrawn |
| `submission_date` | TIMESTAMP | Yes | Formal submission timestamp | Set when status → Submitted |
| `merit_score` | DECIMAL(5,2) | Yes | Computed allocation score | 0–100; computed by scoring algorithm |
| `priority_band` | VARCHAR(10) | Yes | Allocation priority tier | Enum: Band_A (90–100), Band_B (75–89), Band_C (60–74), Band_D (<60) |
| `payment_date` | DATE | Yes | Initial payment confirmation date | Sourced from Treasury API |
| `declaration_signed` | BOOLEAN | No | Applicant declaration | Must be TRUE before submission |
| `supporting_docs` | JSONB | Yes | Uploaded document references | Array of {doc_type, storage_url, uploaded_at} |
| `reviewer_id` | UUID | Yes | Assigned reviewer | FK → staff user |
| `review_notes` | TEXT | Yes | Internal review comments | Restricted to Reviewer+ roles |
| `blockchain_hash` | VARCHAR(256) | Yes | Application record hash | Written on each status change |

---

## payment

Records every financial transaction linked to an application. The Treasury API writes confirmation records via webhook.

| Field | Type | Nullable | Description | Business Rule |
|-------|------|----------|-------------|---------------|
| `payment_id` | UUID | No | Primary key | Auto-generated |
| `application_id` | UUID | No | Parent application | FK → application |
| `payment_ref` | VARCHAR(50) | No | Treasury/REMITA reference | Unique system-wide |
| `payment_type` | VARCHAR(30) | No | Payment category | Enum: Application_Fee, Initial_Deposit, Instalment, Full_Payment, Penalty |
| `amount` | DECIMAL(15,2) | No | Amount paid (NGN) | Must be > 0 |
| `currency` | CHAR(3) | No | Currency code | ISO 4217; default NGN |
| `payment_channel` | VARCHAR(20) | No | Payment method | Enum: Bank_Transfer, USSD, Card, POS, REMITA |
| `payment_status` | VARCHAR(20) | No | Transaction state | Enum: Pending, Confirmed, Failed, Reversed, Disputed |
| `treasury_confirmed` | BOOLEAN | No | Treasury confirmation flag | TRUE only when Treasury API confirms |
| `confirmed_at` | TIMESTAMP | Yes | Treasury confirmation timestamp | Set by inbound Treasury webhook |
| `workflow_triggered` | BOOLEAN | No | Workflow progression flag | TRUE when payment triggers next step |
| `receipt_url` | VARCHAR(500) | Yes | Digital receipt URL | Time-limited signed URL |
| `blockchain_hash` | VARCHAR(256) | Yes | Transaction hash | Written on Treasury confirmation |

---

## allocation

Confirmed unit allocations. Each allocation links one application to one unit — both are unique constraints.

| Field | Type | Nullable | Description | Business Rule |
|-------|------|----------|-------------|---------------|
| `allocation_id` | UUID | No | Primary key | Auto-generated |
| `application_id` | UUID | No | Source application | FK → application; unique |
| `unit_id` | UUID | No | Allocated unit | FK → housing_unit; unique — prevents double allocation |
| `allocated_by` | VARCHAR(10) | No | Allocation method | Enum: System (auto), Staff (manual override) |
| `allocation_date` | TIMESTAMP | No | Confirmation timestamp | Auto-set on creation |
| `allocation_letter_ref` | VARCHAR(50) | Yes | Letter reference number | Unique; generated by document module |
| `letter_generated_at` | TIMESTAMP | Yes | Letter generation time | Set when document module runs |
| `acceptance_status` | VARCHAR(20) | No | Applicant response | Enum: Pending, Accepted, Declined, Expired |
| `acceptance_deadline` | DATE | Yes | Offer acceptance deadline | Typically 14 days from allocation_date |
| `accepted_at` | TIMESTAMP | Yes | Acceptance timestamp | Set when applicant confirms |
| `blockchain_hash` | VARCHAR(256) | Yes | Allocation record hash | Written on allocation and acceptance |

---

## document

All official documents generated by the system — allocation letters, C-of-O, deeds, KYC reports.

| Field | Type | Nullable | Description | Business Rule |
|-------|------|----------|-------------|---------------|
| `document_id` | UUID | No | Primary key | Auto-generated |
| `application_id` | UUID | Yes | Linked application | FK → application |
| `allocation_id` | UUID | Yes | Linked allocation | FK → allocation; populated for post-allocation docs |
| `document_type` | VARCHAR(30) | No | Document category | Enum: Allocation_Letter, C_of_O, Deed_of_Sub_Lease, Receipt, KYC_Report, Survey_Plan |
| `document_ref` | VARCHAR(50) | No | Official reference number | Unique; format: LSH-DOC-YYYY-NNNNN |
| `generated_at` | TIMESTAMP | No | System generation time | Auto-set |
| `generated_by` | VARCHAR(10) | No | Generation method | Enum: System, Staff |
| `storage_url` | VARCHAR(500) | Yes | Encrypted cloud storage URL | Time-limited signed URL only |
| `digital_signature` | TEXT | Yes | Cryptographic signature | SHA-256 signed with Ministry key |
| `blockchain_hash` | VARCHAR(256) | Yes | Document hash on-chain | Enables authenticity verification |
| `status` | VARCHAR(20) | No | Document lifecycle | Enum: Draft, Issued, Signed, Revoked, Archived |
| `issued_at` | TIMESTAMP | Yes | Formal issue timestamp | — |
| `signed_at` | TIMESTAMP | Yes | Digital signature timestamp | — |
| `expiry_date` | DATE | Yes | Document expiry | Applicable to time-limited documents |

---

## audit_log

Append-only immutable log. No UPDATE or DELETE operations are permitted on this table.

| Field | Type | Nullable | Description | Business Rule |
|-------|------|----------|-------------|---------------|
| `log_id` | UUID | No | Primary key | Auto-generated |
| `entity_type` | VARCHAR(50) | No | Affected table name | e.g. APPLICATION, PAYMENT |
| `entity_id` | UUID | No | ID of affected record | — |
| `action` | VARCHAR(20) | No | Action type | Enum: CREATE, UPDATE, DELETE, VIEW, APPROVE, REJECT, ALLOCATE, TRIGGER |
| `performed_by` | UUID | Yes | Actor ID | NULL for system-initiated actions |
| `actor_type` | VARCHAR(20) | No | Actor category | Enum: Applicant, Staff, System, API, Blockchain |
| `previous_value` | JSONB | Yes | Pre-change snapshot | NULL for CREATE actions |
| `new_value` | JSONB | Yes | Post-change snapshot | NULL for DELETE actions |
| `ip_address` | VARCHAR(45) | Yes | Actor IP address | IPv4 or IPv6 |
| `session_id` | VARCHAR(100) | Yes | Session identifier | — |
| `blockchain_hash` | VARCHAR(256) | Yes | Log entry hash | Enables tamper detection |
| `created_at` | TIMESTAMP | No | Exact action timestamp | Append-only; never updated |

---

## scoring_config

Ministry-configurable merit scoring weights. Sum of all active `weight_percent` values must equal 100.

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| `config_id` | UUID | No | Primary key |
| `criterion_key` | VARCHAR(50) | No | Machine-readable key |
| `criterion_label` | VARCHAR(100) | No | Human-readable label |
| `weight_percent` | DECIMAL(5,2) | No | Weight as percentage of total score |
| `max_points` | DECIMAL(5,2) | No | Maximum points for this criterion |
| `data_source` | VARCHAR(100) | Yes | Where data is sourced from |
| `is_active` | BOOLEAN | No | Whether criterion is in use |
| `updated_by` | UUID | Yes | Admin who last updated |
| `updated_at` | TIMESTAMP | No | Last update timestamp |

---

## Encryption Standards

| Classification | Fields | Method |
|---|---|---|
| Highly Sensitive | lasrra_id, nin, bvn, date_of_birth | AES-256 encrypted at rest; masked in UI |
| Sensitive | email, phone_primary, amount | AES-256 encrypted at rest |
| Restricted | storage_url (documents) | Time-limited signed URLs only |
| Internal | review_notes | Role-restricted (Reviewer+ only) |
| Public | blockchain_hash | Plain text — designed for verification |

---

*PCIS — Prime Connection Integrated Solutions Ltd | www.pcis-ltd.com*  
*© 2026 All Rights Reserved | Confidential — Government Use*
