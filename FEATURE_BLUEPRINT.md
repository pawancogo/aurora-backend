# Enterprise E-Commerce Feature Blueprint

> Reference for building each sprint to production depth. Patterns drawn from
> **Amazon** (breadth/ops), **Myntra/Flipkart** (fashion catalog + discovery),
> **Nike / Apple Store** (single-brand premium storefront), and **Shopify**
> (storefront + admin conventions).
>
> Legend: ✅ done · 🟡 partial/scoped · ⬜ gap (not yet scoped) · ⭐ recommended addition
> (was excluded or missing from the original roadmap).

---

## 1. Catalog & Merchandising
- ✅ Hierarchical categories (unlimited depth), brands
- 🟡 Products: slug, SKU, brand, category, description, highlights, specs, dimensions, weight, warranty, HSN/GST, status, featured/new/bestseller *(Sprint 4)*
- 🟡 Variants (color/size/storage/RAM/custom), per-variant price/MRP/SKU/barcode/images/inventory/status *(Sprint 5)*
- 🟡 Media: multiple images, video, 360°/zoom, alt text, ordering *(Sprint 4/5)*
- 🟡 Related / cross-sell / upsell / "frequently bought together" *(Sprint 5/14)*
- ⬜ Size charts & fit guides (per category/brand) ⭐
- ⬜ Product bundles / kits / configurable sets ⭐
- ⬜ Collections / lookbooks / curated shops (manual + rule-based) ⭐
- ⬜ Product comparison ⭐
- ⬜ Attribute-driven facets registry (which attributes are filterable/searchable) 🟡→⭐
- ⬜ Bulk import/export (CSV), bulk edit, media bulk upload ⭐
- ⬜ Product lifecycle: draft → review → publish → archive; scheduled publish ⭐
- ⬜ Digital/downloadable products, gift cards as products ⭐

## 2. Product Detail Page (PDP)
- 🟡 Gallery, variant selector, price/MRP/discount %, stock/low-stock, add to cart/wishlist *(Sprint 5/8)*
- ⬜ Delivery estimate + pincode/ZIP serviceability check ⭐
- ⬜ Size recommendation ("true to size"), size chart modal ⭐
- ⬜ Back-in-stock / restock notify-me ⭐
- ⬜ Ratings summary, review highlights, rating distribution, photo reviews *(Sprint — reviews)*
- ⬜ Product Q&A (customer questions + answers) ⭐
- ⬜ Offers/coupons applicable, EMI/pay-later options, tax-inclusive display ⭐
- ⬜ Recently viewed, "others also viewed", social share ⭐
- ⬜ Rich structured data (Product/Offer/AggregateRating JSON-LD) 🟡 *(SEO sprint)*

## 3. Search & Discovery
- 🟡 Full-text search, autocomplete, filters, sort, pagination/infinite scroll *(Sprint 14)*
- ⬜ Typo tolerance, synonyms, stemming, ranking/relevance tuning ⭐
- ⬜ Faceted filters from attributes (brand/price/rating/size/color/availability/discount) 🟡
- ⬜ Search suggestions, trending/popular searches, zero-result handling + recommendations ⭐
- ⬜ Query rules / merchandising (pin/boost/bury), redirects ⭐
- ⬜ Recently searched, search analytics (top queries, no-result queries) ⭐
- ⬜ (Later) dedicated engine — OpenSearch/Elastic/Meilisearch ⭐

## 4. Cart & Checkout
- 🟡 Persistent cart, variant-level, merge on login, price/stock revalidation *(Sprint 8)*
- 🟡 Guest + login checkout, address selection, shipping, summary, payment, confirmation *(Sprint 9)*
- ⬜ Mini-cart / slide-over, save-for-later, move to wishlist ⭐
- ⬜ Coupon / promo code entry, auto-applied offers, price breakup (item, tax, shipping, discount) ⭐
- ⬜ Gift options (wrap/message), gift cards / store credit / wallet redemption at checkout ⭐
- ⬜ Address autocomplete (Google/postal), pincode serviceability, multiple shipping addresses ⭐
- ⬜ Shipping methods/rates (standard/express), COD eligibility rules, delivery slot ⭐
- ⬜ Checkout as steps or single-page; express checkout (one-click / wallet) ⭐
- ⬜ Order minimums, per-item limits, stock reservation/hold with TTL ⭐
- ⬜ Abandoned cart capture + recovery emails ⭐

## 5. Payments
- 🟡 Provider abstraction (Razorpay/Stripe/UPI/COD), success/failure/pending/retry/refund/webhook *(Sprint 10)*
- ⬜ Saved cards / tokenization, wallets, UPI intent/collect, netbanking, EMI, BNPL ⭐
- ⬜ Partial payments, split (wallet + card), authorize-then-capture, currency handling ⭐
- ⬜ PCI posture (never store PAN; use gateway tokens), 3DS/OTP flows ⭐
- ⬜ Idempotent payment intents, reconciliation, settlement reports ⭐
- ⬜ Refund to source / to store credit; partial refunds ⭐

## 6. Orders & Fulfillment
- 🟡 Lifecycle: pending→confirmed→packed→shipped→delivered→cancelled→refunded→returned, timeline events *(Sprint 9/11)*
- 🟡 Immutable address snapshots + version history + change audit *(Sprint 9/11)*
- ⬜ Order cancellation (customer, within window) + partial cancellation ⭐
- ⬜ Order modification (address/slot) within allowed states 🟡
- ⬜ Split shipments / partial fulfillment, multi-warehouse routing ⭐
- ⬜ Invoice (GST-compliant PDF), packing slip, shipping label, e-way bill ⭐
- ⬜ Carrier/AWB tracking integration + tracking page + webhooks ⭐
- ⬜ Delivery OTP / proof of delivery ⭐

## 7. Returns, Refunds & Exchanges
- 🟡 Return request workflow, admin approve/reject, refund status *(Sprint 12)*
- ⬜ Return eligibility windows/rules per category, non-returnable flags ⭐
- ⬜ Exchange (size/color) vs refund choice; reverse pickup scheduling ⭐
- ⬜ QC on return receipt, restocking, refund to source/store-credit ⭐
- ⬜ RMA numbers, return reasons analytics ⭐

## 8. Customer Account
- ✅ Auth: register/login/logout, email verify, forgot/reset, JWT + refresh rotation
- 🟡 Profile, address book (default, types) *(Sprint 7)*
- ⬜ Order history + reorder, track order, download invoice ⭐
- ⬜ Wishlist(s) / multiple lists / share wishlist *(Sprint 8)* 🟡
- ⬜ Saved cards, wallet/store credit balance + ledger, gift cards ⭐
- ⬜ Notification & communication preferences (email/SMS/push, marketing opt-in) 🟡
- ⬜ Social/OTP login (Google/Apple, phone OTP) ⭐
- ⭐ Account security: sessions/devices list, 2FA, change email/password, delete account (GDPR)

## 9. Reviews, Ratings & UGC
- 🟡 Reviews + ratings *(roadmap: reviews)*
- ⬜ Verified-purchase badge, photo/video reviews, helpful votes, sort/filter ⭐
- ⬜ Moderation queue, profanity filter, seller/admin response ⭐
- ⬜ Product Q&A, review request emails post-delivery ⭐

## 10. Promotions, Pricing & Loyalty  ⭐ (roadmap originally EXCLUDED coupons/flash sales)
- ⬜ Coupons (code, auto), cart/product/category/BOGO/tiered/free-shipping rules, usage limits, stacking rules ⭐
- ⬜ Scheduled sales / flash sales / deal-of-the-day, price drop, strike-through MRP ⭐
- ⬜ Customer-segment pricing, first-order discount, referral program ⭐
- ⬜ Loyalty points / tiers, store credit, gift cards ⭐
- ⬜ Tax engine (GST slabs, HSN, inclusive/exclusive, invoice compliance) 🟡

## 11. CMS & Content
- 🟡 Homepage builder (hero, banners, sections), footer/header, static pages, menus *(Sprint 3/6)*
- ⬜ Block/section registry (drag-drop page builder), scheduling, targeting/segmentation ⭐
- ⬜ Media library / DAM, redirects manager, announcement bar A/B ⭐
- ⬜ Blog / editorial / lookbooks, size-guide content, FAQ manager ⭐
- ⬜ Localized content (i18n), preview/draft mode ⭐

## 12. Personalization & Recommendations  ⭐
- ⬜ Recently viewed, recommended-for-you, trending, "complete the look" ⭐
- ⬜ Homepage/PLP/PDP recommendation slots, cart recommendations ⭐
- ⬜ Segmentation, behavioral events pipeline ⭐

## 13. Notifications & Comms
- 🟡 Transactional email (verify/reset) via SMTP + Sidekiq *(done)*
- ⬜ Full transactional set: order placed/confirmed/shipped/out-for-delivery/delivered, refund, return ⭐
- ⬜ SMS + WhatsApp + push (web/mobile), in-app notification center 🟡
- ⬜ Templating + localization + preference-based suppression, unsubscribe ⭐
- ⬜ Marketing automation hooks (abandoned cart, back-in-stock, win-back) ⭐

## 14. Admin / Back-office (Ops)
- ✅ Session-based server-rendered admin portal (login → dashboard), RBAC (roles/permissions), audit-ready
- 🟡 CRUD for catalog/orders/customers/CMS/settings/nav *(APIs partly; UI Sprint 13)*
- ⬜ Order ops: search/filter, status change, cancel/refund/return, notes, timeline, manual order creation ⭐
- ⬜ Inventory ops: stock adjust, transfers, low-stock alerts, stock history/logs 🟡
- ⬜ Customer ops: view/search, impersonate, credit adjust, block ⭐
- ⬜ Marketing: coupons, banners, sections, campaigns ⭐
- ⬜ Bulk import/export, CSV, saved views, column config ⭐
- ⬜ Audit logs of every admin action, activity feed *(Sprint 16)* 🟡
- ⬜ Multi-admin, granular per-resource permissions ✅(model) 🟡(UI)

## 15. Inventory & Warehouse
- 🟡 Inventory per variant, stock history, logs, low-stock alerts *(Sprint 5)*
- ⬜ Reservations/holds with TTL, oversell protection, backorder/preorder ⭐
- ⬜ Multi-location/warehouse, transfers, availability by location ⭐
- ⬜ Reorder points, supplier/PO (if in scope) ⭐

## 16. Analytics, Reporting & Experimentation
- 🟡 Sales/inventory reports, dashboards *(Sprint 16)*
- ⬜ Funnel (view→cart→checkout→purchase), conversion, AOV, cohort, RFM ⭐
- ⬜ Product/collection performance, search analytics, returns analytics ⭐
- ⬜ Event tracking (GA4/Segment), server-side events, data export ⭐
- ⬜ A/B testing + feature flags 🟡(flags done)

## 17. SEO & Marketing Surface
- 🟡 Meta/canonical/OG/Twitter, sitemap, robots, structured data *(various)*
- ⬜ Per-entity SEO (product/category/CMS), auto-canonical, hreflang, pagination rel ⭐
- ⬜ Dynamic sitemap (products/categories), 301 redirect manager, breadcrumbs + JSON-LD ⭐
- ⬜ Rich results (Product, Breadcrumb, FAQ, Organization), image sitemaps ⭐

## 18. Platform / Non-Functional
- ✅ SSR, Redis caching (nav), background jobs, rate limiting, CORS, JWT, strong params, Brakeman
- 🟡 Perf: image optimization/CDN, code splitting, N+1 elimination, query indexes *(Sprint 16)*
- ⬜ Accessibility (WCAG AA), keyboard nav, focus management, ARIA on all interactive UI ⭐
- ⬜ i18n / l10n (currency, locale, RTL), multi-currency ⭐
- ⬜ Observability: structured logs, error tracking (Sentry), APM, uptime, health SLOs ⭐
- ⬜ Security: 2FA, CSP, secrets mgmt, PII encryption, WAF, bot/fraud protection ⭐
- ⬜ Compliance: GDPR/CCPA (consent, export, delete), cookie consent, PCI, tax/invoice law ⭐
- ⬜ PWA / offline, mobile app API parity ⭐
- ⬜ CI/CD, blue-green/canary, DB migrations strategy, backups/DR, K8s *(Sprint 17)* 🟡

## 19. Integrations (extension points)
- ⬜ Payment gateways, shipping/logistics aggregators (Shiprocket/Delhivery), tax (Avalara),
  email/SMS (SES/Twilio/MSG91), search (Algolia/Meili), analytics, reviews (Yotpo), CDP,
  ERP/accounting, OMS/WMS — all behind adapters/registries ⭐

## 20. Trust, Safety & Support
- ⬜ Help center / FAQ, contact/support ticket, live chat/bot ⭐
- ⬜ Fraud checks (velocity, address/BIN), chargeback handling ⭐
- ⬜ Content moderation (reviews/Q&A), report abuse ⭐

---

## How we apply this
1. **Each existing sprint is now built to blueprint depth** for its domain (not the thin version). Example: Sprint 4 "Catalog" also lands the product lifecycle, media ordering, and facet-attribute registry — not just base fields.
2. **New scope to fold in (were missing/excluded):** Promotions & Loyalty (§10), Personalization (§12), Wallet/Gift cards, Product Q&A, Back-in-stock, Abandoned cart, Size charts, Delivery serviceability, richer Payments (saved cards/EMI), Exchanges, Observability, Accessibility, i18n, Compliance. These become either expanded sprint scopes or new sprints (e.g., "Sprint 10.5 — Promotions & Coupons").
3. **Sequencing unchanged**, depth increased. Before each sprint I'll present the blueprint-aligned scope so we hit ~90% of enterprise expectations per domain in one pass, then harden.

> The original [ROADMAP.md](ROADMAP.md) explicitly excluded coupons/flash sales, loyalty, blog/FAQ, and real gateway/logistics integrations. This blueprint recommends bringing the ⭐ items in. Tell me which ⭐ areas are in-scope so I can update the roadmap accordingly.
