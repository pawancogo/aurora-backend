# Enterprise E-Commerce Platform — Sprint Roadmap

**This is the only sprint list to follow.** One sprint at a time; approval required before starting the next.

> Depth standard: [FEATURE_BLUEPRINT.md](FEATURE_BLUEPRINT.md). External integrations (carriers, SMS, extra gateways) are built behind adapters + mocks until keys exist.

Shipped sprint write-ups live in **Admin → Roadmap** (`/admin/sprints`). Historical narrative (screenshots, gotchas) lives in [PROJECT_STATE.md](PROJECT_STATE.md).

---

## Canonical sprint list (follow this)

| # | Status | Sprint | Notes |
|---|--------|--------|--------|
| 1 | ✅ | Foundation & Infrastructure | Docker, health, CI, Rails + Next.js skeleton |
| 2 | ✅ | Authentication & RBAC | Customer + admin JWT, roles/permissions |
| 3 | ✅ | Navigation & Site Configuration | Categories as menu, settings, feature flags |
| 4 | ✅ | Catalog Core | Products, categories, brands, PLP/PDP |
| 5 | ✅ | Variants, Attributes & Inventory | Variants, stock, reservations |
| 6 | ✅ | CMS & Homepage | Banners, sections, pages, footer |
| 7 | ✅ | Search & Discovery | Facets, autocomplete, recently viewed |
| 8 | ✅ | Cart & Wishlist | Persistent cart, merge on login, wishlist |
| 9 | ✅ | Checkout & Orders | Address snapshot, shipping methods, order history |
| 10 | ✅ | Payments (Razorpay) | Real Razorpay, webhooks, retry |
| 11 | ✅ | Order Fulfillment & Cancellation | Status lifecycle, admin advance, cancel/refund |
| 12 | ✅ | Order Tracking UI | Storefront fulfillment stepper |
| 13 | ✅ | Customer Profile & Address Book | Profile edit + saved addresses (Home/Office/Other, default) |
| 14 | ⬜ | Promotions & Coupons | Codes, cart/product rules, flash sales, free-shipping |
| 15 | ⬜ | Loyalty, Wallet & Gift Cards | Points/tiers, store-credit ledger, gift cards |
| 16 | ✅ | Delivery, Shipments (manual) | Carrier/tracking, packing notes, delivery events. Address change skipped. 3P carrier on the other branch. |
| 17 | ⬜ | Returns, Refunds & Exchanges | RMA, reverse pickup, exchange, refund-to-store-credit |
| 18 | ⬜ | **Reviews, Ratings & Q&A** | Verified-purchase, photo reviews, moderation, product Q&A |
| 19 | ⬜ | Personalization & Recommendations | Recs slots, behavioral events |
| 20 | ⬜ | Notifications & Comms | Full transactional set, SMS/push adapters, preferences |
| 21 | ⬜ | Admin Dashboard & Ops | Remaining ops CRUD, bulk I/O, activity feed |
| 22 | ⬜ | Analytics, Reports & Audit Logs | Funnels, conversion, search/returns analytics, audit trail |
| 23 | ⬜ | SEO & Accessibility | Structured data, sitemaps, redirects, WCAG AA |
| 24 | ⬜ | Performance & Security Hardening | Caching, N+1, CSP, observability, GDPR/consent |
| 25 | ⬜ | Production Readiness & K8s | CI/CD, K8s, secrets, backups/DR, smoke tests |

**Next sprint to start:** **17 — Returns, Refunds & Exchanges.** (14 and 15 skipped for now.)

---

## Do not use these for numbering

| File | Why it conflicts |
|------|------------------|
| [SPRINT_PLAN.md](SPRINT_PLAN.md) | Retired 18-sprint draft. **No Reviews sprint.** Checkout “review” ≠ product reviews. |
| Older `ROADMAP.md` “v2” 23-sprint table | Numbered Profile as #8 and Search as #7, which does **not** match what shipped. |
| Older 17-sprint outline in this file | Numbered Profile as #7, Search as #14, Reports as #16. |

Admin → Roadmap sprints **1–12** already match this list. Sprint **13** (address book) is added there via seed.

### Old number → this list

| Old label (SPRINT_PLAN / old ROADMAP) | Use this # |
|---------------------------------------|------------|
| Profile & Address Book (old #3 / #7 / #8) | **13** |
| Search & Discovery (old #7 / #14) | **7** |
| Cart & Wishlist (old #8 / #9) | **8** |
| Checkout & Orders (old #9 / #10) | **9** |
| Payments (old #10 / #11) | **10** |
| Promotions & Coupons (old v2 #12) | **14** |
| Delivery / shipments (old #11 / #12) | **16** (UI stepper already shipped as **12**) |
| Returns (old #12 / #13) | **17** |
| Reviews, Ratings & Q&A (old v2 #16; missing from SPRINT_PLAN) | **18** |
| Notifications (old #14 / #15) | **20** |
| Admin dashboard (old #13 / #15) | **21** |
| Reports / audit (old #16) | **22** |
| Performance / security (old #16 / #17) | **24** |
| Production / K8s (old #17 / #18) | **25** |

---

## Shipped (1–13, 16)

Details: `/admin/sprints/1` … `/admin/sprints/13`, `/admin/sprints/16`.

| # | What shipped |
|---|--------------|
| 1 | Health/ready APIs, Sidekiq, Compose + CI skeletons, storefront shell |
| 2 | Customer + admin auth, RBAC, protected `/account` |
| 3 | Categories-as-menu, site settings, feature flags, admin portal |
| 4 | Catalog APIs + admin CRUD, PLP/PDP |
| 5 | Variants, inventory adjust/reserve, PDP selector |
| 6 | CMS homepage, banners, pages, footer |
| 7 | Faceted search, infinite scroll, autocomplete, recently viewed |
| 8 | Cart merge, mini-cart, wishlist |
| 9 | Checkout with `OrderAddress` snapshot, order history |
| 10 | Razorpay order + verify + webhook, retry payment |
| 11 | Fulfillment sequence, admin advance, customer/admin cancel, manual refund |
| 12 | Storefront order stepper |
| 13 | Profile edit, address book CRUD, default address, admin read-only addresses |
| 16 | Manual shipment record, carrier/tracking, packing notes, out-for-delivery events, optional delivery notes |

Sprint 13 shipped after checkout on purpose: orders store a **snapshot** (`order_addresses`), not a foreign key to the address book.

Sprint 16 is the **manual** delivery slice. Post-placement address change and OTP/photo proof of delivery were skipped. A third-party carrier adapter lives on a separate branch.

---

## Upcoming sprints (14–25)

### Sprint 14 — Promotions & Coupons

**Goal:** Discount codes and automatic offers on cart/checkout.

**Depends on:** 9, 10  
**Estimate:** 1–2 weeks

- Coupon codes + auto-apply rules (cart/product/category, BOGO, free-shipping, usage limits)
- Flash sales / scheduled sale prices
- Checkout price breakup (item, tax, shipping, discount)
- Admin: coupon CRUD, usage stats

### Sprint 15 — Loyalty, Wallet & Gift Cards

**Goal:** Store credit and loyalty that can pay at checkout.

**Depends on:** 10, 14  
**Estimate:** 1–2 weeks

- Points / tiers, store-credit ledger
- Gift cards as products + redemption
- Wallet + coupon stacking rules
- Admin: credit adjust, gift-card issue/void

### Sprint 16 — Delivery, Shipments (manual) ✅

**Goal:** A shipment record staff can fill by hand, visible on the shopper's order page.

**Depends on:** 11, 12  
**Shipped:** carrier name + tracking number, packing notes, fulfillment/out-for-delivery events, optional delivery notes when marking delivered.

**Skipped:** post-placement address change; OTP/photo proof of delivery; third-party carrier/AWB adapter (other branch).

### Sprint 17 — Returns, Refunds & Exchanges

**Goal:** Customer RMA and staff refund/exchange workflow.

**Depends on:** 11, 15, 16  
**Estimate:** 1–2 weeks

- Return request lifecycle, eligibility windows
- Exchange (size/color) vs refund-to-source / store credit
- Reverse pickup (adapter)
- Admin: approve/reject, QC, restock

### Sprint 18 — Reviews, Ratings & Q&A

**Goal:** Product ratings and reviews on the PDP, plus Q&A and moderation.

**Depends on:** 4, 9, 11  
**Estimate:** 1–2 weeks

This is the sprint that was listed in some roadmaps and **missing from `SPRINT_PLAN.md`**. It is **not built yet** (only `reviews.read` / `reviews.manage` permissions and a `reviews` feature flag exist).

#### Features
- Star rating + written review on PDP
- Ratings summary, distribution, sort/filter
- Verified-purchase badge (reviewer has a delivered order for that product)
- Photo reviews
- Helpful votes
- Product Q&A (ask / answer)
- Admin moderation queue (publish / hide / respond)
- Optional: review-request email after delivery

#### Backend
- `reviews`, `review_images`, `review_votes`, `product_questions`, `product_answers`
- Aggregate rating on product (or cached counter)
- Customers can only review products they purchased (when verified-purchase is on)
- Public list API + authenticated create; admin moderate API

#### Frontend
- PDP ratings summary + review list + write-review form
- Q&A tab
- Account: “reviews to write” from delivered orders

#### Admin
- Moderation queue, respond as store
- Feature flag `reviews` already seeded — wire it to hide the UI when off

#### Testing
- Verified-purchase guard specs
- Moderation authorization specs
- Aggregate rating recalculation specs

### Sprint 19 — Personalization & Recommendations

**Goal:** Recs on homepage, PLP, PDP, and cart.

**Depends on:** 6, 7, 8  
**Estimate:** 1–2 weeks

- Recently viewed (already started in #7) → “recommended for you” / “others also viewed”
- Homepage/PLP/PDP/cart recs slots
- Behavioral events pipeline (view/cart/purchase)

### Sprint 20 — Notifications & Comms

**Goal:** Full transactional set plus preferences.

**Depends on:** 2, 9, 11, 17  
**Estimate:** 1 week

- Order placed/confirmed/shipped/delivered, refund, return emails
- SMS/push adapters (mock until keys)
- In-app notification center + unread badge
- Preference / unsubscribe

### Sprint 21 — Admin Dashboard & Ops

**Goal:** Remaining operational UI (much of catalog/orders/customers already exists).

**Depends on:** 2–13  
**Estimate:** 1–2 weeks

- Dashboard metrics
- Remaining bulk import/export, saved views
- Customer ops (notes, block)
- Activity feed of admin actions

### Sprint 22 — Analytics, Reports & Audit Logs

**Goal:** Sales/ops reporting and an audit trail.

**Depends on:** 21  
**Estimate:** 1–2 weeks

- Sales, inventory, search, returns reports
- Funnel / conversion / AOV
- Audit log of admin mutations

### Sprint 23 — SEO & Accessibility

**Goal:** Crawlable, accessible storefront.

**Depends on:** 4, 6  
**Estimate:** 1 week

- Product/Offer/AggregateRating JSON-LD (needs #18 for real ratings)
- Dynamic sitemaps, 301 manager, breadcrumbs
- WCAG AA pass on core flows (i18n/PWA optional)

### Sprint 24 — Performance & Security Hardening

**Goal:** Production-grade perf and security.

**Depends on:** 1–23  
**Estimate:** 1–2 weeks

- N+1 / query / Redis cache pass
- CSP, secrets, PII posture
- Observability (Sentry/APM)
- GDPR export/delete, cookie consent

### Sprint 25 — Production Readiness & K8s

**Goal:** Deployable production artifacts.

**Depends on:** 24  
**Estimate:** 1 week

- Production images, K8s manifests, secrets, backups/DR
- CI/CD + smoke tests
- OpenAPI complete

---

## Still out of scope (extension points only)

- Marketplace / multi-vendor
- Barcode scanning
- OTP delivery confirmation
- Real carrier/SMS until keys are provided (adapters ship in #16 / #20)

Coupons, loyalty, reviews, and real Razorpay are **in scope** (sprints 14, 15, 18, and 10).

---

## Approval gate

**Current status:** Sprints **1–13 complete.** Next: **Sprint 14 — Promotions & Coupons.**

After each sprint: update Admin → Roadmap, append [PROJECT_STATE.md](PROJECT_STATE.md) if needed, then wait for approval before starting the next number on this list.
