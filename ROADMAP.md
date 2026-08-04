# Enterprise E-Commerce Platform — Sprint Roadmap

Single-company e-commerce platform. Incremental, production-quality delivery. One sprint at a time; approval required before each new sprint.

---

## Sprint Overview (v2 — blueprint-aligned)

> **Depth standard: [FEATURE_BLUEPRINT.md](FEATURE_BLUEPRINT.md).** Scope expanded to include all
> ⭐ areas (Promotions/Loyalty, Personalization, Advanced Payments/Fulfillment, Platform Hardening).
> Each sprint is built to blueprint depth; full scope is presented at kickoff. External integrations
> (real payment gateways, carriers, SMS) are built behind **adapters + mocks** and wired live when keys exist.

| #  | Sprint | Blueprint depth folded in |
|----|--------|----------------------------|
| 1  | ✅ Foundation & Infrastructure | — |
| 2  | ✅ Authentication & RBAC | (2FA/social login later) |
| 3  | ✅ Navigation & Site Configuration | — |
| 4  | Catalog Core | product lifecycle, media ordering, tax/HSN, bulk import/export |
| 5  | Variants, Attributes & Inventory | facet-attribute registry, reservations, stock history + low-stock alerts |
| 6  | CMS & Homepage | block/section builder, media library, per-entity SEO |
| 7  | Search & Discovery | faceted filters, autocomplete, synonyms, recently viewed, no-result recs |
| 8  | Customer Profile & Address Book | pincode serviceability, account security (sessions) |
| 9  | Cart & Wishlist | mini-cart, save-for-later, back-in-stock, abandoned-cart capture |
| 10 | Checkout & Orders | address snapshots, shipping methods, gift options, price breakup |
| 11 | Payments | saved cards/UPI/EMI/COD adapters (mock), GST invoice PDF |
| 12 | ⭐ Promotions & Coupons | codes, cart/product rules, flash sales, free-shipping |
| 13 | ⭐ Loyalty, Wallet & Gift Cards | points/tiers, store-credit ledger, gift cards |
| 14 | Delivery, Shipments & Tracking | carrier/AWB adapter (mock), tracking page, address-change audit |
| 15 | ⭐ Returns, Refunds & Exchanges | RMA, reverse pickup, exchange, refund-to-store-credit |
| 16 | ⭐ Reviews, Ratings & Q&A | verified-purchase, photo reviews, moderation, product Q&A |
| 17 | ⭐ Personalization & Recommendations | recently viewed, recs slots, behavioral events |
| 18 | Notifications & Comms | full transactional set, SMS/push adapters, preferences, marketing hooks |
| 19 | Admin Dashboard & Ops | full CRUD UI, order/inventory/customer/marketing ops, bulk I/O, audit feed |
| 20 | Analytics, Reports & Audit Logs | funnels, conversion, search/returns analytics, audit trail |
| 21 | ⭐ SEO & Accessibility | structured data, dynamic sitemaps, redirects, WCAG AA (i18n/PWA optional) |
| 22 | Performance & Security Hardening | caching, N+1, CSP, observability (Sentry/APM), GDPR/consent |
| 23 | Production Readiness & K8s | CI/CD, K8s, secrets, backups/DR, smoke tests |

### Original 17-sprint outline (kept for reference; the v2 table above is authoritative)

| Sprint | Goal | Depends On | Est. Duration |
|--------|------|------------|---------------|
| 1 | Foundation & Infrastructure | — | 1 week |
| 2 | Authentication & RBAC | Sprint 1 | 1–2 weeks |
| 3 | Navigation & Site Configuration | Sprint 2 | 1–2 weeks |
| 4 | Catalog Core (Categories, Brands, Products) | Sprint 3 | 2 weeks |
| 5 | Product Variants, Attributes & Inventory | Sprint 4 | 2 weeks |
| 6 | CMS & Homepage Management | Sprint 3 | 1–2 weeks |
| 7 | Customer Profile & Address Book | Sprint 2 | 1 week |
| 8 | Cart & Wishlist | Sprint 4, 7 | 1–2 weeks |
| 9 | Checkout, Orders & Address Snapshots | Sprint 7, 8 | 2 weeks |
| 10 | Payment Provider Abstraction & Flow | Sprint 9 | 1–2 weeks |
| 11 | Delivery, Shipments & Address Change Workflow | Sprint 9, 10 | 2 weeks |
| 12 | Returns & Refunds | Sprint 11 | 1–2 weeks |
| 13 | Admin Dashboard & Operations | Sprint 2–12 | 2 weeks |
| 14 | Search, Filters & Product Discovery | Sprint 4, 5 | 1–2 weeks |
| 15 | Notifications & Order Tracking (Customer) | Sprint 9, 11 | 1 week |
| 16 | Reports, Audit Logs & Performance Hardening | Sprint 13 | 1–2 weeks |
| 17 | Production Readiness & K8s | Sprint 16 | 1 week |

---

## Sprint 1 — Foundation & Infrastructure

**Goal:** Runnable monorepo with Rails API, Next.js frontend, PostgreSQL, Redis, Sidekiq, Docker Compose, and CI skeleton.

### Features
- Monorepo directory layout
- Docker Compose for local development
- Rails 7+ API-only application
- Next.js (App Router) with TypeScript and TailwindCSS
- shadcn/ui baseline setup
- Health check endpoints
- Environment configuration pattern
- GitHub Actions CI (lint + test skeleton)

### Backend Tasks
- Initialize Rails API with PostgreSQL, Redis, Sidekiq
- Configure CORS, secure headers, rack-attack skeleton
- Add rswag/OpenAPI setup
- Base API versioning (`/api/v1`)
- ApplicationController, error handling, pagination base
- RSpec + FactoryBot setup

### Frontend Tasks
- Initialize Next.js with TypeScript, TailwindCSS
- Install shadcn/ui, TanStack Query, Zustand, Axios, Zod
- API client with interceptors skeleton
- App layout shell (header/footer placeholders fed by API later)
- Environment configuration

### Admin Tasks
- None (infrastructure only)

### Database Changes
- No business tables yet
- Enable UUID extension, audit column conventions documented

### API Changes
- `GET /api/v1/health`
- `GET /api/v1/ready`

### Testing
- Backend: health endpoint request spec
- Frontend: Vitest + RTL setup, smoke test for root layout

### Completion Checklist
- [ ] `docker compose up` starts all services
- [ ] Rails API responds on health endpoint
- [ ] Next.js dev server runs and renders
- [ ] CI pipeline runs on push
- [ ] No placeholder business logic
- [ ] PROJECT_STATE.md updated

---

## Sprint 2 — Authentication & RBAC

**Goal:** Secure customer and admin authentication with JWT, refresh tokens, email verification, password reset, and role-based access control.

### Features
- Customer registration, login, logout
- Email verification
- Forgot / reset password
- JWT access + refresh token rotation
- Admin login (separate namespace)
- Roles & permissions (RBAC)
- Rate limiting on auth endpoints

### Backend Tasks
- User model (STI or role association — customer vs admin)
- Devise + devise-jwt configuration
- Refresh token model and rotation service
- Role, Permission, RolePermission models
- Pundit policies for base authorization
- Mailers for verification and password reset
- `/api/v1/customer/auth/*` endpoints
- `/api/v1/admin/auth/*` endpoints
- Seed default roles and permissions

### Frontend Tasks
- Login, register, forgot password, reset password pages
- Email verification confirmation page
- Auth store (Zustand) + token refresh logic
- Protected route middleware
- Admin login page (separate route group)

### Admin Tasks
- Roles list/create/edit (API only this sprint; UI in Sprint 13)
- Permissions read API

### Database Changes
- `users`, `roles`, `permissions`, `role_permissions`, `user_roles`
- `refresh_tokens`
- Audit fields on all tables

### API Changes
- Customer: register, login, logout, refresh, verify email, forgot/reset password, me
- Admin: login, logout, refresh, me
- Admin: roles CRUD, permissions index

### Testing
- Model, service, policy, and request specs for all auth flows
- Frontend: form validation and auth redirect tests

### Completion Checklist
- [ ] Customer can register, verify email, login, refresh, logout
- [ ] Admin can login with RBAC enforced
- [ ] Rate limiting active on auth routes
- [ ] All tests pass

---

## Sprint 3 — Navigation & Site Configuration

**Goal:** Fully dynamic, unlimited-depth navigation hierarchy and core site settings — all API-driven.

### Features
- Self-referential navigation tree (mega menu)
- Ordering, icons, images, slugs, SEO, visibility, scheduling
- Site settings key-value store
- Feature flags

### Backend Tasks
- `navigation_items` (parent_id, position, slug, metadata JSONB)
- `site_settings`, `feature_flags` models
- Navigation tree serializer (nested, unlimited depth)
- Admin CRUD for navigation and settings
- Public read APIs with visibility/scheduling filters
- Redis cache for navigation tree

### Frontend Tasks
- Dynamic mega menu component (Myntra-style)
- Mobile navigation drawer
- Settings/feature-flag hooks via TanStack Query

### Admin Tasks
- Navigation tree editor (drag-and-drop ordering)
- Settings and feature flag management APIs

### Database Changes
- `navigation_items`, `site_settings`, `feature_flags`

### API Changes
- Public: `GET /api/v1/navigation`, `GET /api/v1/settings`, `GET /api/v1/feature_flags`
- Admin: full CRUD for above

### Testing
- Navigation tree building, scheduling, visibility specs
- Frontend mega menu rendering tests

---

## Sprint 4 — Catalog Core

**Goal:** Categories, brands, and base product model with metadata-driven design.

### Features
- Hierarchical categories (same parent-child pattern as navigation)
- Brands
- Products with slug, SEO, soft delete
- Product images (Active Storage)
- Base pricing and tax class association

### Backend Tasks
- Category, Brand, Product, TaxClass models
- Active Storage configuration
- Product listing with Kaminari pagination
- Ransack filters foundation
- Admin product CRUD
- Public product read APIs

### Frontend Tasks
- Product listing page (grid, pagination)
- Product detail page (base — variants in Sprint 5)
- Category and brand browse pages

### Admin Tasks
- Category, brand, product management APIs
- Image upload endpoints

### Database Changes
- `categories`, `brands`, `products`, `tax_classes`
- Active Storage tables
- Indexes on slug, status, foreign keys

### API Changes
- Public: products index/show, categories, brands
- Admin: full CRUD

### Testing
- Model validations, soft delete, image attachment specs
- Request specs for public and admin APIs

---

## Sprint 5 — Variants, Attributes & Inventory

**Goal:** Metadata-driven product variants, attributes, specifications, and inventory tracking.

### Features
- Product attributes and attribute values (metadata-driven)
- Variants with SKU, price, inventory
- Specifications
- Related / recommended / new arrivals / best sellers (data model + APIs)

### Backend Tasks
- Attribute, AttributeValue, ProductVariant, ProductSpecification models
- Inventory service with reservation logic foundation
- Variant selection API for product detail
- Admin variant and inventory management

### Frontend Tasks
- Variant selector on product detail
- Stock availability display
- Related products section

### Admin Tasks
- Attribute definition management
- Variant and inventory admin APIs

### Database Changes
- `attributes`, `attribute_values`, `product_variants`, `product_specifications`
- `inventory_items`, composite indexes on SKU

### Testing
- Inventory deduction/reservation specs
- Variant combination uniqueness specs

---

## Sprint 6 — CMS & Homepage Management

**Goal:** Admin-managed homepage, banners, footer, header announcement, and static pages — zero frontend deploys for content changes.

### Features
- Homepage banners and promotional banners
- Homepage sections (configurable blocks)
- Footer links and content
- Header announcement bar
- Static pages: About, Contact, Privacy, Terms, Shipping, Returns
- SEO metadata per page/section

### Backend Tasks
- Banner, HomepageSection, FooterSection, StaticPage models
- Section type registry (extensible block types)
- Scheduling and visibility on banners
- Public aggregated homepage API

### Frontend Tasks
- Homepage rendering from API sections
- Banner carousel
- Static page renderer
- Dynamic footer and announcement bar

### Admin Tasks
- CMS CRUD APIs for all content types

### Database Changes
- `banners`, `homepage_sections`, `footer_sections`, `static_pages`

### Testing
- Homepage aggregation service specs
- Section scheduling specs

---

## Sprint 7 — Customer Profile & Address Book

**Goal:** Customer profile management and saved addresses (separate from order addresses).

### Features
- Profile view/edit
- Address book: add, edit, delete, default, type (Home/Office/Other)

### Backend Tasks
- CustomerProfile model (or extend User)
- Address model scoped to customer address book
- Default address logic (single default constraint)
- Pundit: customers manage own addresses only

### Frontend Tasks
- Profile page
- Address book UI with CRUD

### Admin Tasks
- View customer addresses (read-only)

### Database Changes
- `customer_profiles`, `addresses` (address book — not order-linked)

### Testing
- Default address switching specs
- Authorization specs

---

## Sprint 8 — Cart & Wishlist

**Goal:** Persistent cart and wishlist with variant-level granularity.

### Features
- Add/update/remove cart items
- Cart merge on login
- Wishlist add/remove
- Real-time price/inventory validation

### Backend Tasks
- Cart, CartItem, Wishlist, WishlistItem models
- Cart service with inventory/price validation
- Guest cart via session token (optional) + merge on auth

### Frontend Tasks
- Cart page and mini-cart
- Wishlist page
- Add-to-cart / add-to-wishlist on product detail

### Admin Tasks
- None

### Database Changes
- `carts`, `cart_items`, `wishlists`, `wishlist_items`

### Testing
- Cart calculation, merge, validation specs

---

## Sprint 9 — Checkout, Orders & Address Snapshots

**Goal:** Order placement with immutable address snapshots — never reference live customer address on orders.

### Features
- Checkout flow (addresses, shipping method selection, order summary)
- Order creation with shipping address snapshot
- Order items from cart
- Order status lifecycle foundation
- Configurable editable address states (admin setting)

### Backend Tasks
- Order, OrderItem, OrderAddress models (snapshot — not FK to Address)
- OrderAddressVersion for version history
- OrderAddressChangeLog for audit trail
- Checkout service orchestrating cart → order
- ShippingMethod model (configurable, no provider integration)
- Eligibility service for address edits based on admin config

### Frontend Tasks
- Checkout steps: address → shipping → review → place order
- Order confirmation page
- Order history and order detail (customer)

### Admin Tasks
- Order list/show APIs
- Configurable editable order states setting

### Database Changes
- `orders`, `order_items`, `order_addresses`, `order_address_versions`, `order_address_change_logs`
- `shipping_methods`

### Testing
- Snapshot immutability: changing address book does not change order
- Order placement integration specs

---

## Sprint 10 — Payment Provider Abstraction & Flow

**Goal:** Complete payment flow with provider abstraction (Stripe/Razorpay/PayU pluggable later).

### Features
- Payment method selection
- Mock payment provider implementation
- Processing, success, failure, pending, retry, cancel flows
- Receipt and invoice generation (PDF)

### Backend Tasks
- PaymentProvider interface + registry
- MockProvider implementation
- Payment, PaymentAttempt models
- Payment state machine
- Invoice/receipt generation service

### Frontend Tasks
- Payment selection step
- Processing / success / failure / pending pages
- Retry and cancel actions
- Invoice download

### Admin Tasks
- Payment list/show, manual status override (authorized roles)

### Database Changes
- `payments`, `payment_attempts`

### Testing
- Provider abstraction specs, state transition specs

---

## Sprint 11 — Delivery, Shipments & Address Change Workflow

**Goal:** Shipment lifecycle using latest approved shipping address; full address change audit trail.

### Features
- Shipment creation and status timeline
- Delivery dashboard (admin)
- Customer delivery address update (eligible states only)
- Address version increment on change with full audit
- Admin manual address update when allowed

### Backend Tasks
- Shipment, ShipmentEvent models
- Shipment uses latest OrderAddress version
- AddressChangeService: preserve original, create version, log change
- Admin-configurable editable states (from site_settings)
- Customer and admin address update endpoints

### Frontend Tasks
- Order tracking page with shipment timeline
- Delivery address update form (when eligible)
- Admin shipment management UI foundation

### Admin Tasks
- Shipment CRUD, timeline view
- Address change history viewer
- Manual address update

### Database Changes
- `shipments`, `shipment_events`
- Extend `order_address_change_logs` if needed

### Testing
- Address change blocked in non-editable states
- Audit trail completeness specs
- Shipment uses latest address version

---

## Sprint 12 — Returns & Refunds

**Goal:** Return request workflow and refund processing (no payment gateway — internal state only).

### Features
- Customer return request
- Admin approve/reject return
- Refund request and status tracking
- Link returns to original order and shipment

### Backend Tasks
- ReturnRequest, Refund models and state machines
- Return eligibility rules service
- Admin workflow APIs

### Frontend Tasks
- Return request form on order detail
- Return/refund status display

### Admin Tasks
- Returns and refunds management

### Database Changes
- `return_requests`, `refunds`

### Testing
- Return eligibility and refund state specs

---

## Sprint 13 — Admin Dashboard & Operations

**Goal:** Full admin panel for day-to-day operations.

### Features
- Dashboard with key metrics
- Users, roles, permissions UI
- Products, categories, brands, inventory UI
- Orders, returns, refunds, payments UI
- CMS management UI
- Marketing (banners/sections) UI
- Settings, feature flags, audit-config UI

### Backend Tasks
- Dashboard aggregation APIs
- Reports foundation endpoints

### Frontend Tasks
- Admin app route group with layout
- All admin pages wired to existing APIs

### Admin Tasks
- Complete admin UI coverage

### Testing
- Admin authorization integration tests
- Dashboard API specs

---

## Sprint 14 — Search, Filters & Product Discovery

**Goal:** Search with metadata-driven filters, recently viewed, infinite scroll.

### Features
- Full-text search (PostgreSQL tsvector or dedicated later)
- Dynamic filters from attributes
- Recently viewed products
- Infinite scroll on listing pages

### Backend Tasks
- Search service with Ransack/filters
- RecentlyViewed model
- Redis cache for popular queries

### Frontend Tasks
- Search page with filters
- Recently viewed section
- Infinite scroll integration

### Testing
- Search and filter accuracy specs

---

## Sprint 15 — Notifications & Customer Order Experience

**Goal:** In-app and email notifications for order lifecycle events.

### Features
- Notification preferences
- Order status notifications
- Email templates for key events

### Backend Tasks
- Notification model, NotificationService
- Sidekiq jobs for async delivery
- Mailer templates

### Frontend Tasks
- Notification center
- Preference settings

### Testing
- Notification dispatch specs

---

## Sprint 16 — Reports, Audit Logs & Performance

**Goal:** Operational visibility and performance hardening.

### Features
- Audit logs for admin actions
- Sales and inventory reports
- Query optimization pass
- Redis caching strategy
- N+1 elimination audit

### Backend Tasks
- AuditLog model with automatic logging concern
- Report services
- Bullet gem / query profiling fixes

### Frontend Tasks
- Code splitting audit
- Image optimization (next/image)
- Lazy loading

### Testing
- Performance regression benchmarks
- Audit log completeness specs

---

## Sprint 17 — Production Readiness & Kubernetes

**Goal:** Production deployment artifacts and final hardening.

### Features
- Kubernetes manifests (deployment, service, ingress, configmaps)
- Production Docker images
- Secrets management pattern
- Final security review
- OpenAPI documentation complete

### Backend Tasks
- Production configs, log aggregation hooks
- Sidekiq deployment manifest

### Frontend Tasks
- Production build optimization
- Standalone output for container

### Infrastructure Tasks
- K8s manifests in `/infrastructure`
- GitHub Actions deploy workflow skeleton
- Health/readiness probes

### Testing
- Full test suite green
- Smoke tests in CI

---

## Explicitly Excluded (Architectural Extension Points Only)

- Marketplace / multi-vendor
- Coupons / flash sales
- Blogs, testimonials, FAQs
- Barcode scanning
- OTP delivery confirmation
- Real payment gateway integration (Sprint 10 provides abstraction)
- Real delivery provider integration

Architecture must allow adding these later without major refactors.

---

## Approval Gate

**Current status:** ✅ **Sprint 5 — Variants, Attributes & Inventory complete.** Awaiting approval for **Sprint 6 — CMS & Homepage Management**.

After each sprint: update `PROJECT_STATE.md`, summarize completed work, list pending work, and wait for approval before continuing.
