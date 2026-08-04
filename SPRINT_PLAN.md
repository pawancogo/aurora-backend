# Sprint Plan — Enterprise E-Commerce Platform

> ⚠️ **SUPERSEDED.** This document is retained for history only. The canonical plan is
> [ROADMAP.md](ROADMAP.md) (17 sprints). Do not use this file for sprint scope.

> Created: 2026-07-15  
> Status: Superseded by ROADMAP.md

## Overview

18 sprints organized by dependency order. Each sprint produces a deployable, tested increment. No sprint begins until the previous one is approved.

---

## Sprint 1 — Foundation & Dev Environment

**Goal:** Runnable monorepo with backend API skeleton, frontend shell, Docker Compose, and CI pipeline.

| Area | Tasks |
|------|-------|
| Backend | Rails 7 API-only app, PostgreSQL, Redis, Sidekiq, CORS, health endpoint, base error handling, Swagger setup |
| Frontend | Next.js App Router, TypeScript, TailwindCSS, shadcn/ui, Axios client, TanStack Query provider, Zustand store shell |
| Infrastructure | Docker Compose (postgres, redis, backend, frontend, sidekiq), GitHub Actions CI (lint + test) |
| Database | Base audit fields concern (`created_at`, `updated_at`, soft delete pattern) |
| Testing | RSpec setup, Vitest + RTL setup, smoke specs |

**Dependencies:** None  
**Estimate:** 3–4 days

---

## Sprint 2 — Authentication & RBAC

**Goal:** Secure customer and admin authentication with role-based access control.

| Area | Tasks |
|------|-------|
| Backend | Devise JWT (access + refresh tokens), customer registration/login/logout, email verification, password reset, admin auth namespace |
| RBAC | Roles, permissions, Pundit policies, seed default roles (customer, admin, support) |
| Frontend | Login, register, forgot password, email verification pages; auth store; protected routes |
| Admin | Admin login, session management |
| Security | Rate limiting (rack-attack), secure headers |
| Testing | Request specs for auth flows, policy specs |

**Dependencies:** Sprint 1  
**Estimate:** 4–5 days

---

## Sprint 3 — Customer Profile & Address Book

**Goal:** Customer profile management and reusable address book.

| Area | Tasks |
|------|-------|
| Backend | Profile CRUD, address book CRUD, default address, address types (Home/Office/Other), validation |
| Frontend | Profile page, address list/add/edit/delete, default toggle |
| Admin | View customer profiles and addresses (read-only) |
| Testing | Model, service, request specs |

**Dependencies:** Sprint 2  
**Estimate:** 3 days

---

## Sprint 4 — Dynamic Navigation & CMS Foundation

**Goal:** Fully configurable navigation and static content management.

| Area | Tasks |
|------|-------|
| Backend | Hierarchical navigation (unlimited nesting, ordering, icons, images, slugs, SEO, visibility, scheduling), CMS pages (About, Contact, Privacy, Terms, Shipping, Returns), footer config, header announcement |
| Frontend | Mega menu component (Myntra-style), footer, header announcement bar, static page renderer |
| Admin | Navigation tree editor, CMS page editor, footer/announcement management |
| Testing | Navigation nesting specs, CMS CRUD specs |

**Dependencies:** Sprint 2  
**Estimate:** 5 days

---

## Sprint 5 — Catalog Foundation (Brands, Categories, Attributes)

**Goal:** Metadata-driven product catalog structure.

| Area | Tasks |
|------|-------|
| Backend | Brands, hierarchical categories, attribute definitions, attribute values, tax classes |
| Admin | Brand/category/attribute CRUD, tax class management |
| Frontend | Category listing pages (shell) |
| Testing | Model validations, admin API specs |

**Dependencies:** Sprint 2  
**Estimate:** 4 days

---

## Sprint 6 — Products, Variants & Inventory

**Goal:** Full product management with variants, SKU, pricing, and inventory.

| Area | Tasks |
|------|-------|
| Backend | Products, variants, specifications, images (Active Storage), inventory tracking, pricing, discounts, related/recommended products |
| Admin | Product CRUD, variant management, image upload, inventory adjustment, bulk operations |
| Frontend | Product detail page (basic) |
| Testing | Product/variant/inventory service specs |

**Dependencies:** Sprint 5  
**Estimate:** 6 days

---

## Sprint 7 — Product Discovery (Search, Filters, Listing)

**Goal:** Customers can browse, search, and filter products.

| Area | Tasks |
|------|-------|
| Backend | Product listing API (Ransack filters, Kaminari pagination), search endpoint, sort options |
| Frontend | PLP with filters, sort, pagination/infinite scroll, search results page |
| Performance | Query optimization, eager loading, Redis caching for filter facets |
| Testing | Search/filter request specs, frontend component tests |

**Dependencies:** Sprint 6  
**Estimate:** 4 days

---

## Sprint 8 — Homepage & Marketing CMS

**Goal:** Fully CMS-driven homepage and promotional content.

| Area | Tasks |
|------|-------|
| Backend | Homepage banners, promotional banners, homepage sections (featured, new arrivals, best sellers), SEO metadata API |
| Admin | Banner/section scheduler, drag-and-drop ordering |
| Frontend | Homepage with all dynamic sections, lazy loading, image optimization |
| Testing | Homepage API specs, section visibility/scheduling specs |

**Dependencies:** Sprint 4, Sprint 6  
**Estimate:** 4 days

---

## Sprint 9 — Cart & Wishlist

**Goal:** Shopping cart and wishlist functionality.

| Area | Tasks |
|------|-------|
| Backend | Cart CRUD (add/update/remove/clear), cart merge on login, wishlist CRUD, recently viewed tracking |
| Frontend | Cart page, mini cart, wishlist page, add-to-cart/wishlist on PLP/PDP |
| Testing | Cart service specs, concurrency handling |

**Dependencies:** Sprint 6, Sprint 2  
**Estimate:** 4 days

---

## Sprint 10 — Checkout & Order Placement

**Goal:** Complete checkout flow with immutable order address snapshots.

| Area | Tasks |
|------|-------|
| Backend | Checkout session, shipping method selection, order creation, **order address snapshot** (not linked to customer address), order items, order status machine |
| Frontend | Checkout steps (address → shipping → review → place order), order confirmation |
| Admin | Order list, order detail view |
| Database | `order_addresses`, `orders`, `order_items`, `order_status_transitions` |
| Testing | Order placement specs, address snapshot immutability specs |

**Dependencies:** Sprint 3, Sprint 9  
**Estimate:** 5 days

---

## Sprint 11 — Payment System

**Goal:** Full payment flow with provider abstraction (no real gateway yet).

| Area | Tasks |
|------|-------|
| Backend | Payment provider interface, mock provider, payment intents, status transitions (success/failure/pending), retry/cancel, receipt/invoice generation |
| Frontend | Payment selection, processing screen, success/failure/pending pages, retry flow, receipt download |
| Admin | Payment list, payment detail, manual status override |
| Testing | Payment service specs, state machine specs |

**Dependencies:** Sprint 10  
**Estimate:** 5 days

---

## Sprint 12 — Delivery & Shipment Tracking

**Goal:** Shipment lifecycle with configurable address change rules.

| Area | Tasks |
|------|-------|
| Backend | Shipment model, status timeline, delivery dashboard API, **address version history** with audit trail, configurable editable states |
| Frontend | Order tracking page, delivery timeline |
| Admin | Shipment management, address change history view, manual address update |
| Database | `shipments`, `shipment_events`, `order_address_versions`, `address_change_logs` |
| Testing | Address versioning specs, state eligibility specs |

**Dependencies:** Sprint 10  
**Estimate:** 5 days

---

## Sprint 13 — Returns & Refunds

**Goal:** Customer return requests and admin refund workflow.

| Area | Tasks |
|------|-------|
| Backend | Return request lifecycle, refund workflow, refund status tracking |
| Frontend | Return request form, return status page |
| Admin | Return approval/rejection, refund processing |
| Testing | Return/refund service specs |

**Dependencies:** Sprint 11, Sprint 12  
**Estimate:** 4 days

---

## Sprint 14 — Notifications

**Goal:** Customer and admin notification system.

| Area | Tasks |
|------|-------|
| Backend | Notification model, email templates (order placed, shipped, delivered, return approved), in-app notifications, Sidekiq delivery |
| Frontend | Notification center, unread badge |
| Admin | Notification templates management |
| Testing | Notification service specs |

**Dependencies:** Sprint 10  
**Estimate:** 3 days

---

## Sprint 15 — Admin Dashboard, Reports & Audit

**Goal:** Operational visibility for administrators.

| Area | Tasks |
|------|-------|
| Backend | Dashboard metrics API, sales reports, audit log (paper_trail or custom), user activity tracking |
| Admin | Dashboard UI, reports page, audit log viewer |
| Testing | Report generation specs, audit log specs |

**Dependencies:** Sprint 10, Sprint 11  
**Estimate:** 4 days

---

## Sprint 16 — Settings, Feature Flags & SEO

**Goal:** Global configuration and feature toggles.

| Area | Tasks |
|------|-------|
| Backend | Site settings API, feature flags, shipping methods config, payment methods config, address-editable-states config |
| Admin | Settings panel, feature flag toggles |
| Frontend | Dynamic meta tags, sitemap, robots.txt from API |
| Testing | Settings/feature flag specs |

**Dependencies:** Sprint 4  
**Estimate:** 3 days

---

## Sprint 17 — Performance & Security Hardening

**Goal:** Production-grade performance and security.

| Area | Tasks |
|------|-------|
| Backend | N+1 audit, query optimization, Redis caching strategy, background job optimization |
| Frontend | Code splitting, image optimization, lazy loading audit |
| Security | OWASP review, input sanitization audit, JWT rotation, CSP headers |
| Infrastructure | Kubernetes-ready manifests, production Docker configs |
| Testing | Load test baseline, security spec suite |

**Dependencies:** All prior sprints  
**Estimate:** 4 days

---

## Sprint 18 — End-to-End QA & Launch Readiness

**Goal:** Full regression, documentation, and launch checklist.

| Area | Tasks |
|------|-------|
| QA | Full E2E test suite, cross-browser testing, mobile responsiveness audit |
| Docs | API documentation (Swagger complete), deployment guide |
| DevOps | Production deployment pipeline, monitoring setup |
| Testing | E2E specs for critical paths (browse → cart → checkout → pay → track) |

**Dependencies:** Sprint 17  
**Estimate:** 4 days

---

## Dependency Graph

```
S1 → S2 → S3 ──────────────────────────────┐
      ↓                                     │
      S4 ──────────────────────┐            │
      S5 → S6 → S7             │            │
           ↓    S8 ← S4        │            │
           S9 ← S2             │            │
           ↓                   │            │
      S10 ← S3, S9             │            │
       ↓                       │            │
      S11, S12                 │            │
       ↓                       │            │
      S13                      │            │
      S14 ← S10                │            │
      S15 ← S10, S11           │            │
      S16 ← S4                 │            │
       ↓                       │            │
      S17 (all)                │            │
      S18 (all)                │            │
```

## Total Estimate

~70–75 engineering days across 18 sprints.
