# LSIHP — Prototype Overview
**Version:** 1.0 | **Date:** April 2026  
**Prepared by:** PCIS — Prime Connection Integrated Solutions Ltd

---

## Overview

A functional prototype of the Lagos State Integrated Housing Portal (LSIHP) has been developed using the **Base44** rapid application development platform. The prototype demonstrates the end-to-end applicant journey and the core administrative workflows, validating the product requirements before full production development begins.

The prototype is accessible to authorised Ministry reviewers upon request to PCIS.

---

## What the Prototype Demonstrates

### Applicant-Facing Flows
| Flow | Status |
|------|--------|
| Applicant registration & profile creation | ✅ Complete |
| LASRRA ID / NIN input and KYC simulation | ✅ Complete |
| Housing scheme browsing and selection | ✅ Complete |
| Application form submission with declaration | ✅ Complete |
| Payment reference generation (simulated) | ✅ Complete |
| Application status tracking dashboard | ✅ Complete |
| Allocation notification and acceptance | ✅ Complete |
| Document download (simulated allocation letter) | ✅ Complete |

### Ministry Admin Flows
| Flow | Status |
|------|--------|
| Reviewer dashboard — application queue | ✅ Complete |
| Merit score display and ranking view | ✅ Complete |
| Manual approval / rejection workflow | ✅ Complete |
| Allocation trigger and unit assignment | ✅ Complete |
| Document generation (simulated) | ✅ Complete |
| Audit log view | ✅ Complete |

---

## Prototype vs Production Scope

| Feature | Prototype | Production |
|---------|-----------|-----------|
| KYC | Simulated | Live LASRRA/NIMC API |
| Payments | Simulated | Live REMITA + Treasury API |
| Blockchain | Not included | Hyperledger Fabric |
| Documents | PDF mock | Digitally signed, blockchain-anchored |
| Merit scoring | Static demo | Live algorithm (6-criteria) |
| Database | In-memory | PostgreSQL 15 |
| Security | Basic | OAuth 2.0, AES-256, RBAC |

---

## User Flows

### Flow 1 — Applicant Registration & KYC
```
1. Applicant visits portal
2. Enters LASRRA ID, NIN, BVN, date of birth
3. System calls KYC service → LASRRA verification
4. On success: applicant profile created, kyc_status = Verified
5. On failure: applicant flagged, notified, application blocked
```

### Flow 2 — Application Submission
```
1. Verified applicant browses active housing schemes
2. Selects scheme → reviews eligibility criteria
3. Completes application form → signs declaration
4. Pays application fee (REMITA)
5. Treasury confirms payment → application_status = Submitted
6. System generates application_ref (LSH-YYYY-NNNNN)
```

### Flow 3 — Merit Scoring & Allocation
```
1. After submission deadline, algorithm scores all applications
2. Applications ranked by merit_score DESC → priority bands assigned
3. Ministry reviewer reviews ranked list
4. System auto-allocates: top-ranked applicants → available units
5. Allocation letter generated, applicant notified
6. Applicant accepts within deadline → C-of-O process initiated
```

---

## Access

To request access to the prototype for technical review, contact:

**Charles Iyoha — CEO, PCIS**  
📧 charlesi@pcis-ltd.com  
📱 +1 (902) XXX-XXXX  
🌐 www.pcis-ltd.com

---

*PCIS — Prime Connection Integrated Solutions Ltd | www.pcis-ltd.com*  
*© 2026 All Rights Reserved | Confidential — Government Use*
