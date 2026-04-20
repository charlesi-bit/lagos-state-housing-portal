# LSIHP — Third-Party Integration Specifications
**Version:** 1.0 | **Date:** April 2026  
**Prepared by:** PCIS — Prime Connection Integrated Solutions Ltd

---

## Integration Overview

| Integration | Purpose | Module | Direction |
|-------------|---------|--------|-----------|
| LASRRA | Identity verification, residency data | Module A | Outbound |
| NIMC | NIN validation | Module A | Outbound |
| REMITA | Payment processing | Module D | Bidirectional |
| Lagos State Treasury | Payment confirmation | Module D | Inbound (webhook) |
| IPPIS | Civil service grade verification | Module B | Outbound |
| LIRS | Income band verification | Module B | Outbound |
| Lands Bureau | Property ownership cross-check | Module B | Outbound |
| Hyperledger Fabric | Blockchain anchoring | All modules | Outbound |

---

## LASRRA Integration

**Lagos State Residents Registration Agency**  
Used for: Identity verification (E-KYC), residency duration, ghost applicant detection

### Connection Details
```
Endpoint:       https://api.lasrra.lagosstate.gov.ng/v1
Auth:           OAuth 2.0 Client Credentials
Timeout:        10 seconds
Retry:          3 attempts with exponential backoff
SLA:            99.5% uptime | <2s response time
```

### Key Operations
- `POST /verify` — Full identity check (NIN + BVN + biometric match)
- `GET /resident/{lasrra_id}` — Retrieve resident profile
- `GET /resident/{lasrra_id}/ownership` — Check property ownership history

### Failure Handling
- If LASRRA is unavailable: queue KYC request; notify applicant of delay
- If identity mismatch: flag record; do not allow application submission
- All LASRRA responses stored in audit_log with blockchain_hash

---

## REMITA Integration

**REMITA by SystemSpecs**  
Used for: Payment initiation, confirmation, receipting

### Connection Details
```
Endpoint:       https://remitademo.net/remita/exapp/api/v1 (staging)
                https://login.remita.net/remita/exapp/api/v1 (production)
Auth:           API Key + SHA-512 Hash
Timeout:        30 seconds
```

### Key Operations
- Generate RRR (REMITA Retrieval Reference) for each payment
- Poll payment status via RRR
- Receive confirmation webhook → trigger LSIHP workflow

### Payment Flow
```
1. LSIHP generates RRR → sends to applicant
2. Applicant pays via any REMITA channel (bank, USSD, card, POS)
3. REMITA notifies Treasury
4. Treasury webhook confirms to LSIHP → workflow auto-advances
```

---

## Hyperledger Fabric Blockchain

**Permissioned blockchain for immutable record-keeping**

### Network Configuration
```
Network Type:   Permissioned (government-grade)
Consensus:      Raft (CFT)
Channel:        lsihp-channel
Chaincode:      lsihp-records-cc (Go)
Peers:          Ministry of Housing, ICT Unit, Lands Bureau
Orderer:        Lagos State Government orderer nodes
```

### Anchored Events
| Event | Data Hashed |
|-------|-------------|
| KYC Verified | applicant_id + result + timestamp |
| Application Status Change | application_id + old_status + new_status + actor |
| Allocation Issued | allocation_id + unit_id + applicant_id + date |
| Payment Confirmed | payment_ref + amount + confirmed_at |
| Document Issued | document_id + type + digital_signature |
| Unit Status Change | unit_id + old_status + new_status |

---

*PCIS — Prime Connection Integrated Solutions Ltd | www.pcis-ltd.com*
