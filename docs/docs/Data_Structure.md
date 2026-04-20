# LSIHEP Data Structure & Architecture

## Data Classification (NDPR Compliance)

| Classification | Examples | Security Level |
|---------------|----------|----------------|
| **Public** | Estate names, unit types, allocation stats | Standard encryption |
| **Internal** | Maintenance logs, vendor lists, internal notes | RBAC access control |
| **Confidential** | Names, NIN, LASRRA ID, phone, email | AES-256 encryption |
| **Restricted** | Bank accounts, payment details, legal cases | Double encryption + audit log |

---

## Core Database Tables

### 1. User & Identity Management

**`users`**
- `user_id` (PK, UUID)
- `email` (unique, indexed)
- `phone_hash` (encrypted)
- `password_hash` (bcrypt)
- `role_id` (FK)
- `is_verified` (boolean)
- `created_at`, `updated_at`

**`profiles`**
- `profile_id` (PK, UUID)
- `user_id` (FK, indexed)
- `nin_number` (encrypted, indexed)
- `lasrra_id` (encrypted)
- `bvn_hash` (encrypted)
- `full_name`
- `dob`
- `lga_id` (FK)
- `employment_status`
- `income_range`

**`identity_verifications`**
- `verification_id` (PK)
- `profile_id` (FK)
- `source` (LASRRA/NIN/BVN)
- `status` (verified/pending/failed)
- `verified_at`
- `expiry_date`

**`audit_logs`** (Immutable)
- `log_id` (PK)
- `user_id` (FK)
- `action`
- `ip_address`
- `timestamp`
- `resource_type`
- `resource_id`
- `blockchain_hash` (optional)

---

### 2. Housing Inventory

**`estates`**
- `estate_id` (PK, UUID)
- `name`
- `lga_id` (FK)
- `address`
- `total_units`
- `amenities_json`
- `status` (active/inactive)

**`blocks`**
- `block_id` (PK)
- `estate_id` (FK, indexed)
- `block_name`
- `floor_count`

**`units`**
- `unit_id` (PK, UUID)
- `block_id` (FK, indexed)
- `unit_number`
- `type` (1BR/2BR/3BR/4BR)
- `size_sqm`
- `price_band`
- `status` (Available/Reserved/Allocated/Occupied/Maintenance)
- `amenities_json`

**`unit_media`**
- `media_id` (PK)
- `unit_id` (FK)
- `file_url`
- `type` (Photo/Floorplan/Certificate)

---

### 3. Applications & Allocation

**`applications`**
- `app_id` (PK, UUID)
- `profile_id` (FK, indexed)
- `estate_preference_id` (FK)
- `submission_date`
- `status` (Draft/Submitted/Under Verification/Eligible/Awaiting Payment/Cleared/Allocated)
- `merit_score`
- `created_at`, `updated_at`

**`application_documents`**
- `doc_id` (PK)
- `app_id` (FK, indexed)
- `doc_type` (ID/PaySlip/TaxClearance/Photo)
- `file_url`
- `verification_status`

**`allocations`**
- `allocation_id` (PK, UUID)
- `app_id` (FK, indexed)
- `unit_id` (FK, indexed)
- `allocation_date`
- `quota_category`
- `offer_status` (Pending/Accepted/Rejected)
- `blockchain_hash`

**`waitlists`**
- `waitlist_id` (PK)
- `estate_id` (FK)
- `profile_id` (FK)
- `rank`
- `created_at`

---

### 4. Financials & Reconciliation

**`invoices`**
- `invoice_id` (PK, UUID)
- `allocation_id` (FK, indexed)
- `amount`
- `due_date`
- `type` (Rent/Deposit/ApplicationFee)
- `status` (Pending/Paid/Overdue)

**`payments`**
- `payment_id` (PK, UUID)
- `invoice_id` (FK, indexed)
- `transaction_ref` (REMITA)
- `amount_paid`
- `payment_date`
- `channel` (REMITA/BankTransfer/Card)
- `status` (Success/Failed/Pending)

**`reconciliation_queue`** ⚠️ **90-Day Window**
- `recon_id` (PK)
- `payment_id` (FK, indexed)
- `treasury_ref`
- `status` (Pending/Matched/Mismatch)
- `deadline_date` (90 days from payment)
- `days_remaining` (calculated)

**`clearance_certificates`**
- `clearance_id` (PK, UUID)
- `allocation_id` (FK, indexed)
- `issued_by` (user_id FK)
- `issued_at`
- `certificate_ref` (CLR-2026-XXXX)
- `blockchain_hash`

**`arrears`**
- `arrear_id` (PK)
- `allocation_id` (FK)
- `amount_owed`
- `days_overdue`
- `notice_level` (5day/15day/30day)

---

### 5. Maintenance & Operations

**`maintenance_tickets`**
- `ticket_id` (PK, UUID)
- `unit_id` (FK, indexed)
- `reported_by` (user_id FK)
- `category` (Plumbing/Electrical/HVAC/Appliance/Pest/Structural)
- `urgency` (Emergency/Urgent/Routine)
- `status` (Open/InProgress/Assigned/Completed)
- `created_at`, `updated_at`

**`work_orders`**
- `order_id` (PK)
- `ticket_id` (FK, indexed)
- `assigned_to` (vendor_id FK)
- `sla_deadline`
- `completion_proof` (JSON with photos)

**`vendors`**
- `vendor_id` (PK)
- `company_name`
- `service_category`
- `compliance_docs`

---

### 6. Legal & E-Title

**`documents_vault`**
- `doc_id` (PK, UUID)
- `owner_id` (FK, indexed)
- `doc_type` (CofO/Deed/Lease/Notice)
- `file_url` (encrypted storage)
- `issue_date`
- `expiry_date`
- `is_verified`

**`transfer_requests`**
- `transfer_id` (PK)
- `unit_id` (FK)
- `current_owner` (profile_id FK)
- `proposed_buyer` (profile_id FK)
- `price`
- `status` (Pending/UnderReview/Approved/Rejected)
- `govt_rofr_status` (Waived/Exercised)

**`notices`**
- `notice_id` (PK, UUID)
- `recipient_id` (FK)
- `template_type` (RentReminder/LatePayment/FinalNotice/Eviction)
- `sent_date`
- `delivery_status`
- `legal_acknowledgement`

---

## Entity Relationships

### Key Relationships:
- **One-to-Many**: User → Applications (but only 1 active allocation)
- **One-to-One**: Allocation ↔ Unit (during occupancy)
- **One-to-Many**: Estate → Blocks → Units
- **Many-to-Many**: Users ↔ Roles (via junction table)
- **Immutable Link**: Allocations/Payments → Audit Logs (via blockchain hash)

---

## Indexing Strategy

**High-Priority Indexes:**
- `profiles.nin_number` (unique)
- `applications.profile_id` + `applications.status`
- `allocations.unit_id` + `allocations.status`
- `payments.transaction_ref` (unique)
- `reconciliation_queue.deadline_date` + `reconciliation_queue.status`
- `maintenance_tickets.status` + `maintenance_tickets.created_at`

---

## Security Architecture

### Encryption:
- **At Rest**: AES-256 for `profiles`, `payments`, `documents_vault`
- **In Transit**: TLS 1.3 for all API and web traffic
- **Passwords**: Bcrypt with salt (cost factor 12)

### Data Residency:
- **Primary Database**: Hosted in Nigeria/West Africa region
- **Backups**: Geo-redundant within West Africa
- **Compliance**: NDPR + Lagos State ICT Data Sovereignty

### Audit Trail:
- **Critical Events**: Application submission, Allocation decision, Payment clearance, Title transfer
- **Mechanism**: Hash written to permissioned blockchain ledger
- **Verification**: Public portal can verify hash without revealing data

---

## Scalability

- **Database Engine**: PostgreSQL 14+ with connection pooling
- **Caching**: Redis for sessions and frequent queries
- **Concurrency**: Designed for 10,000+ concurrent users
- **Storage**: S3-compatible object storage (infinitely scalable)

---

## Data Retention Policy

| Data Type | Retention Period | Disposal Method |
|-----------|-----------------|-----------------|
| Application Records | 10 years | Archive to cold storage |
| Financial Records | 7 years (Tax Law) | Secure delete |
| Audit Logs | Permanent | Immutable ledger |
| Inactive User Data | 5 years | Anonymization |
| Maintenance Logs | 5 years | Archive |

---

*Last Updated: March 2026*  
*Prepared by: PCIS Limited Technical Team*
