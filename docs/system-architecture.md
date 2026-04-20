# LSIHP — System Architecture
**Version:** 1.0 | **Date:** April 2026  
**Prepared by:** PCIS — Prime Connection Integrated Solutions Ltd  
**Classification:** Confidential — Government Use

---

## Architecture Overview

The LSIHP is built on a cloud-native microservices architecture, deployed on government-compliant cloud infrastructure within Nigerian jurisdiction. Each of the four functional modules operates as an independent service, communicating via a secure internal API gateway.

```
                          ┌─────────────────────────────────────┐
                          │         CITIZEN PORTAL               │
                          │   (Next.js — Public-Facing)          │
                          └────────────────┬────────────────────┘
                                           │ HTTPS
                          ┌────────────────▼────────────────────┐
                          │         ADMIN DASHBOARD              │
                          │   (React — Ministry Internal)        │
                          └────────────────┬────────────────────┘
                                           │
                          ┌────────────────▼────────────────────┐
                          │           API GATEWAY                │
                          │  (Auth | Rate Limit | Routing)       │
                          └──┬───────┬──────────┬───────────────┘
                             │       │          │
              ┌──────────────▼─┐  ┌──▼───────┐  ┌▼────────────────┐
              │  KYC Service   │  │ Scoring  │  │ Document Service │
              │  (Module A)    │  │ Service  │  │  (Module C)      │
              └──────┬─────────┘  │(Module B)│  └────────┬─────────┘
                     │            └──────────┘           │
              ┌──────▼─────────────────────────────────────────────┐
              │              Payment Service (Module D)             │
              │         Treasury Webhook Listener                   │
              └──────────────────────────┬─────────────────────────┘
                                         │
              ┌──────────────────────────▼─────────────────────────┐
              │                  DATA LAYER                         │
              │   PostgreSQL │ Redis Cache │ Elasticsearch           │
              └──────────────────────────┬─────────────────────────┘
                                         │
              ┌──────────────────────────▼─────────────────────────┐
              │            BLOCKCHAIN LAYER                         │
              │         Hyperledger Fabric                          │
              └─────────────────────────────────────────────────────┘
```

---

## Technology Stack

### Frontend
| Component | Technology | Purpose |
|-----------|-----------|---------|
| Citizen Portal | Next.js 14 (React) | Public-facing application portal |
| Admin Dashboard | React 18 + TypeScript | Ministry reviewer and admin interface |
| UI Framework | Tailwind CSS | Consistent, accessible design |
| State Management | Redux Toolkit | Complex application state |

### Backend
| Component | Technology | Purpose |
|-----------|-----------|---------|
| API Gateway | Kong / AWS API Gateway | Auth, routing, rate limiting |
| Microservices | Node.js + NestJS | All four module services |
| Message Queue | RabbitMQ | Async payment/KYC events |
| Job Scheduler | Bull (Node.js) | Background scoring, reminders |

### Data Layer
| Component | Technology | Purpose |
|-----------|-----------|---------|
| Primary Database | PostgreSQL 15 | Transactional application data |
| Cache | Redis 7 | Session management, queue |
| Search | Elasticsearch 8 | Applicant search, audit queries |
| Object Storage | AWS S3 / Azure Blob | Document storage (encrypted) |
| Blockchain | Hyperledger Fabric | Immutable record anchoring |

### Infrastructure
| Component | Specification |
|-----------|--------------|
| Cloud | AWS GovCloud / Azure Government (Nigeria region) |
| Container | Docker + Kubernetes (EKS/AKS) |
| CI/CD | GitHub Actions |
| Monitoring | Prometheus + Grafana |
| Logging | ELK Stack (Elasticsearch, Logstash, Kibana) |
| SSL/TLS | Let's Encrypt / AWS Certificate Manager |
| CDN | CloudFront (static assets only) |

---

## Security Architecture

### Layers of Defence
1. **Network Layer** — WAF (Web Application Firewall), DDoS protection, IP allowlisting for government networks
2. **API Layer** — OAuth 2.0, JWT (RS256), rate limiting, CORS policy
3. **Application Layer** — Input validation, parameterised queries, RBAC
4. **Data Layer** — AES-256 encryption at rest, TLS 1.3 in transit
5. **Audit Layer** — Immutable audit log + blockchain anchoring

### Compliance
- **NDPR (Nigeria Data Protection Regulation)** — full compliance
- **NITDA Guidelines** — data localisation within Nigeria
- **ISO 27001** — information security management framework (target)
- **OWASP Top 10** — all critical vulnerabilities addressed

---

## Performance Targets

| Metric | Target |
|--------|--------|
| API Response Time (p95) | < 500ms |
| KYC Verification Time | < 3 seconds |
| Payment Webhook Processing | < 5 seconds |
| Document Generation | < 10 seconds |
| Portal Uptime SLA | 99.5% |
| Concurrent Users | 10,000+ |
| Applicant Capacity | 200,000+ |
| Database Throughput | 1,000 TPS |

---

## Deployment Phases

| Phase | Scope | Timeline |
|-------|-------|----------|
| Phase 1 | Discovery & Requirements | Complete |
| Phase 2 | Prototype (Base44) | In Progress |
| Phase 3 | MVP Development | Pending Approval |
| Phase 4 | UAT & Security Audit | TBD |
| Phase 5 | Pilot Launch (1 scheme) | TBD |
| Phase 6 | Full Production Rollout | TBD |

---

*PCIS — Prime Connection Integrated Solutions Ltd | www.pcis-ltd.com*  
*© 2026 All Rights Reserved | Confidential — Government Use*
