# LSIHP — Entity Relationship Diagram (ERD)
**Version:** 1.0 | **Date:** April 2026  
**Prepared by:** PCIS — Prime Connection Integrated Solutions Ltd

---

## Entity Relationship Summary

```
APPLICANT ──────────────────── APPLICATION ─────────── ALLOCATION ─── HOUSING_UNIT
    │                1:1 (per scheme)    │    1:1              │  1:1       │
    │                                   │                      │            │
    │ 1:M                               │ 1:M                  │ 1:M        │ M:1
    │                                   │                      │            │
 DOCUMENT                            PAYMENT               DOCUMENT   HOUSING_SCHEME
                                                                          │
                                                                          │ 1:M
                                                                          │
                                                                     HOUSING_UNIT

ALL ENTITIES ──── 1:M ──── AUDIT_LOG
```

---

## Relationship Definitions

| Entity A | Cardinality | Entity B | Description |
|----------|-------------|----------|-------------|
| APPLICANT | 1 : 1 per scheme | APPLICATION | One applicant submits one application per scheme |
| APPLICANT | 1 : M | DOCUMENT | An applicant can have multiple KYC and supporting documents |
| APPLICATION | 1 : 1 | ALLOCATION | One approved application produces one allocation |
| APPLICATION | 1 : M | PAYMENT | An application has multiple payment transactions |
| APPLICATION | 1 : M | DOCUMENT | An application generates multiple official documents |
| ALLOCATION | 1 : 1 | HOUSING_UNIT | Each allocation is assigned exactly one unit |
| HOUSING_SCHEME | 1 : M | HOUSING_UNIT | A scheme contains many individual units |
| HOUSING_SCHEME | 1 : M | APPLICATION | A scheme receives many applications |
| ALL ENTITIES | 1 : M | AUDIT_LOG | Every change to every entity is logged immutably |

---

## Workflow State Machine

### Application Status Flow
```
Draft ──► Submitted ──► Under_Review ──► Approved ──► Allocated
                                    └──► Rejected
              └──► Withdrawn (at any stage before Allocated)
```

### Payment Status Flow
```
Pending ──► Confirmed ──► [triggers next workflow step]
       └──► Failed
       └──► Reversed
       └──► Disputed
```

### Allocation Acceptance Flow
```
Pending ──► Accepted ──► [C-of-O and Deed generation triggered]
       └──► Declined ──► [unit returned to Available pool]
       └──► Expired  ──► [after acceptance_deadline passes]
```

### Document Status Flow
```
Draft ──► Issued ──► Signed ──► Archived
                └──► Revoked
```

---

## Key Constraints

1. **One application per scheme per applicant** — enforced by UNIQUE(applicant_id, scheme_id) on application table
2. **One allocation per unit** — enforced by UNIQUE(unit_id) on allocation table — prevents double allocation
3. **One allocation per application** — enforced by UNIQUE(application_id) on allocation table
4. **Immutable audit log** — no UPDATE or DELETE permitted on audit_log table
5. **Blockchain anchoring** — blockchain_hash written on every critical state change across all 6 core tables

---

*PCIS — Prime Connection Integrated Solutions Ltd | www.pcis-ltd.com*
