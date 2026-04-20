# LSIHP — Technical Summary
**Version:** 1.0 | **Date:** April 2026  
**Prepared by:** PCIS — Prime Connection Integrated Solutions Ltd  
**Prepared for:** Lagos State Ministry of Housing & ICT Unit  
**Classification:** Confidential — Government Use

---

## 1. Project Background

The Lagos State Ministry of Housing has identified critical inefficiencies in the current manual housing allocation process, including:

- **Ghost applicants** — duplicate registrations undermining fairness
- **Lack of transparency** — allocation decisions not auditable by citizens
- **Manual document workflows** — delays in Certificate of Occupancy and deed issuance
- **Payment reconciliation gaps** — manual Treasury matching causing processing delays
- **No real-time visibility** — applicants cannot track application status

PCIS was engaged to design and deliver a Blockchain-enabled Cloud Portal — the Lagos State Integrated Housing Portal (LSIHP) — to eliminate these issues through technology.

---

## 2. Solution Summary

The LSIHP is a four-module digital platform:

| Module | Name | Core Function |
|--------|------|---------------|
| A | Smart Application & E-KYC | LASRRA identity verification; ghost applicant elimination |
| B | Automated Merit-Based Allocation | Algorithm-driven ranking; transparent, auditable allocation |
| C | Digital Documentation (E-Deeds) | Automated allocation letters, C-of-O, Sub-lease Deeds |
| D | Real-time Payment Integration | Treasury API link; automated workflow triggering |

---

## 3. Key Technical Decisions

### Blockchain Layer
Hyperledger Fabric (permissioned) was selected over public blockchains because:
- Government-grade access control — only authorised Ministry nodes participate
- No transaction fees (unlike Ethereum)
- Compliant with NITDA data sovereignty requirements
- Proven in government identity and land registry use cases globally

### PostgreSQL as Primary Database
Selected for ACID compliance, JSONB support (flexible document metadata), and mature ecosystem for government-scale deployments.

### LASRRA Integration (Not Standalone KYC)
Rather than building a separate biometric system, LSIHP integrates directly with the existing LASRRA infrastructure — reducing cost, leveraging existing government investment, and ensuring single source of truth for Lagos resident identity.

### REMITA for Payments
REMITA is the standard government payment gateway in Nigeria, already mandated for state-level transactions. Integration ensures full Treasury reconciliation compliance.

---

## 4. Performance Baseline

Based on the current allocation data from the Ministry ICT Unit:

| Metric | Current (Manual) | LSIHP Target | Improvement |
|--------|-----------------|--------------|-------------|
| Application processing time | 30 days | 3 days | 90% reduction |
| Ghost applicant rate | ~15% | ~0% | Eliminated via E-KYC |
| Allocation letter issuance | 14 days | Same day | 99% reduction |
| Payment reconciliation | 5 days | Real-time | 100% reduction |
| Audit query response | Manual (days) | <1 second | Full automation |
| Document authenticity checks | Manual | Blockchain-instant | Full automation |

---

## 5. Security Summary

- All PII encrypted at rest (AES-256) and in transit (TLS 1.3)
- OAuth 2.0 + JWT authentication on all API endpoints
- Role-Based Access Control (RBAC) — least privilege principle
- Immutable audit log + blockchain anchoring on all critical transactions
- NDPR compliant — data localised within Nigeria
- NITDA registered — government cloud standards met

---

## 6. Repository Structure

```
lagos-state-housing-portal/
├── README.md                          ← Project overview
├── docs/
│   ├── technical-summary.md           ← This document
│   └── system-architecture.md         ← Architecture diagrams & stack
├── database/
│   ├── schema.sql                     ← Full PostgreSQL schema
│   ├── data-dictionary.md             ← Field-level documentation
│   └── erd.md                         ← Entity relationship model
├── integrations/
│   ├── api-contracts.md               ← All module API specifications
│   └── third-party-integrations.md    ← LASRRA, REMITA, Treasury specs
└── prototype/
    └── prototype-overview.md          ← Base44 prototype documentation
```

---

## 7. Contact

**Charles Iyoha — Founder & CEO**  
PCIS — Prime Connection Integrated Solutions Ltd  
📧 charlesi@pcis-ltd.com  
🌐 www.pcis-ltd.com  
📍 Halifax, Nova Scotia, Canada | Abuja, Nigeria | Johannesburg, South Africa

---

*© 2026 PCIS — Prime Connection Integrated Solutions Ltd. All Rights Reserved.*  
*Confidential — For Lagos State Ministry of Housing Review Only.*
