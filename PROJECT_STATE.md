# Project State

> Living document. Updated at the end of every sprint. Single source of truth for what
> exists, what is pending, and any deviations from the plan.

## Current Position

- **Active sprint:** Sprint 7 — Search & Discovery ✅ complete
- **Status:** Sprints 1–7 done. Next: Sprint 8 — Cart & Checkout.
- **Canonical roadmap:** [ROADMAP.md](ROADMAP.md) (17 sprints). `SPRINT_PLAN.md` is **superseded**.
- **⚠ Sprint-numbering note:** "Sprint 7" as tracked here = **Search & Discovery** (SPRINT_PLAN's numbering + this project's UI tags such as the buy-box "Add to cart — Sprint 8"). The *canonical* ROADMAP.md instead labels Sprint 7 = "Customer Profile & Address Book" and files search/discovery under feature #7 / its Sprint 14. The content is done regardless of the label; the canonical Profile & Address Book work (full profile edit + address book; a read-only `/account` stub exists) is still pending. Reconcile the labels in a future pass if desired.

## Locked Architectural Decisions (ADRs)

| #        | Decision            | Choice                                                                                                       | Date       |
| -------- | ------------------- | ------------------------------------------------------------------------------------------------------------ | ---------- |
| ADR-001  | Repo layout         | Two **independent** git repos — `backend/` (Rails API) + `frontend/` (Next.js) — grouped in one folder for convenience. Each self-contained: own Dockerfile, docker-compose, CI, .gitignore, scripts. Communicate only over HTTP. | 2026-07-22 |
| ADR-002  | Backend framework   | Rails 8.1 API-only, Ruby 3.4.2                                                                                | 2026-07-20 |
| ADR-003  | Frontend framework  | Next.js 16 (App Router), React 19, TypeScript, Tailwind v4, shadcn/ui                                        | 2026-07-20 |
| ADR-004  | Primary keys        | Plain `bigint` everywhere. Enumeration risk on public resources accepted; slugs used for SEO-facing URLs.    | 2026-07-20 |
| ADR-005  | Background jobs      | Sidekiq + Redis (Rails Solid Queue/Cache/Cable skipped)                                                       | 2026-07-20 |
| ADR-006  | API contract         | Versioned under `/api/v1`; standard envelope `{ data, meta }` on success, `{ error }` on failure             | 2026-07-20 |
| ADR-007  | Client state         | TanStack Query + server/URL state. No global client store introduced until a concrete need justifies it.     | 2026-07-20 |
| ADR-008  | Auth mechanism       | Custom JWT (`has_secure_password` + `jwt`) with rotating refresh tokens — not Devise. Full control over API tokens + rotation. | 2026-07-22 |
| ADR-009  | Principals           | Separate `customers` (buyers) and `admin_users` (RBAC staff) tables — distinct login surfaces; a customer can never hold a staff permission. | 2026-07-22 |
| ADR-010  | Refresh tokens       | Opaque, stored as SHA-256 digests, single-use with rotation + revoke-on-reuse; access JWT ~15 min, refresh ~30 days. | 2026-07-22 |
| ADR-011  | Fonts                | System font stack (no build-time Google Fonts fetch) for hermetic builds; brand fonts can be vendored via `next/font/local` later. | 2026-07-22 |
| ADR-012  | Token storage (web)  | Tokens in `localStorage` + non-sensitive cookie flag for middleware. Refresh-on-401 interceptor. httpOnly-cookie hardening noted for later. | 2026-07-22 |
| ADR-013  | Navigation           | ~~Self-referential `navigation_items` (unlimited depth), Redis-cached per location.~~ **SUPERSEDED by ADR-016** — the menu is now the Categories tree. | 2026-07-22 |
| ADR-016  | Navigation (menu)    | **Storefront menu = the visible `categories` tree** — single source of truth. Top-level categories are the top menu, descendants show on hover (any depth) via the mega menu; `visible` flag = show/hide, `position` = order. `navigation_items` retired (table/model/API/services removed). Managed entirely in the admin Categories section. | 2026-07-27 |
| ADR-014  | SMTP                 | Real email via SMTP when `SMTP_ADDRESS` is set (all envs except test); otherwise dev writes to `tmp/mails`. Config in `config/initializers/smtp.rb`, creds in gitignored `.env`. | 2026-07-22 |
| ADR-015  | Admin portal         | Server-rendered Rails ERB at `/admin`, **session-authenticated** (cookies) — per spec, not a separate frontend. Backend root `/` → `/admin` → dashboard if signed in, else login. Distinct from the stateless JWT `/api/v1/admin/*` API. Re-added `Rack::MethodOverride` + Cookies/Session/Flash to the api_only app. | 2026-07-23 |

## Environment Notes / Deviations

- **Repos are independent** (ADR-001). Tooling lives per-repo (`Dockerfile`, `docker-compose.yml`,
  `.github/workflows/ci.yml`, `scripts/`). The container folder (`ecomWebApp/`) is **not** a git
  repo; the planning docs (ROADMAP/PROJECT_STATE/SPRINT_PLAN) live there loosely, tracked by neither app.
- **Docker daemon not running** in the build environment. `docker-compose.yml` and the
  `docker/` images are authored as Sprint 1 deliverables but are **not runtime-verified**.
  The stack is instead verified running natively: local PostgreSQL + `redis-server` +
  Rails / Sidekiq / Next.js processes. Re-verify Compose once a Docker daemon is available.

## Sprint Log

### Sprint 1 — Foundation & Infrastructure ✅ (completed 2026-07-22)

Definition of Done:

- [x] `docker compose up` config authored (db, redis, api, sidekiq, web) — verified natively (Docker daemon unavailable in this env)
- [x] `/api/v1/health` (200) and `/api/v1/ready` (200 / 503 when Redis down) respond with the standard envelope
- [x] Unknown routes return the JSON 404 envelope
- [x] Homepage SSR renders and displays live API health; client pill uses TanStack Query + CORS
- [x] Sample Sidekiq job enqueues and processes (immediate **and** scheduled/delayed paths)
- [x] RuboCop clean, Brakeman 0 warnings, ESLint + tsc clean; RSpec 6/6, Vitest 5/5, `next build` green
- [x] CI workflow present (`.github/workflows/ci.yml`)
- [x] README + PROJECT_STATE + consolidated ROADMAP
- [x] No business tables, no placeholder business logic

Notable decisions/fixes during the sprint:
- Pinned `connection_pool ~> 2.5` — v3.0 broke Sidekiq 7.3's scheduler poller (`TimedStack#pop`).
- Deferred the Sidekiq::Web dashboard to Sprint 13 (needs admin RBAC + session; not worth extra middleware in an API-only app now).
- Added `backend/.ruby-version` (3.4.2) and `frontend/.nvmrc` (24) to pin the toolchain.
- Frontend uses Base UI primitives (shadcn `base-nova` style); `Button` composes via `render`, not `asChild`.

### Sprint 2 — Authentication & RBAC ✅ (completed 2026-07-22)

Delivered:
- **DB:** `customers`, `admin_users`, `roles`, `permissions`, `role_permissions`, `admin_user_roles`, `refresh_tokens`.
- **Customer auth:** register → email verify (auto-login) → login (verified-only) → refresh (rotation) → logout → `/me`; forgot/reset password (enumeration-safe, revokes sessions).
- **Admin auth:** login/refresh/logout/`/me` + RBAC-gated `GET /admin/roles`, `/admin/permissions`.
- **RBAC:** 30 permissions, 6 seeded roles, super-admin implicit-all, permission-gated endpoints via `AdminAuthentication#authorize_permission!`.
- **Security:** bcrypt, hashed refresh/verify/reset tokens, Rack::Attack throttles on auth routes, cross-principal token rejection.
- **Frontend:** auth context + refresh-on-401 interceptor; pages login/register/forgot/reset/verify-email/admin-login + protected `/account`; edge middleware; RHF+Zod forms.

Verification:
- Backend: **29 RSpec examples pass**, RuboCop clean, Brakeman 0; live curl walkthrough of both principals + rotation + RBAC.
- Frontend: **10 Vitest tests pass**, tsc + ESLint clean, `next build` green (8 routes + middleware); live in-browser register → API → DB insert confirmed.

Notable decisions/fixes:
- `JsonWebToken.encode` needed an explicit `{ }` hash (Ruby 3.4 kwargs parsing) — same class of gotcha as the Struct init in Sprint 1.
- Dropped `next/font/google` for a system stack (ADR-011) — the build env can't reach the font CDN, and hermetic builds are better practice.
- Reworked auth effects to satisfy Next 16's `react-hooks/set-state-in-effect` rule (no synchronous setState in effects).
- Seeded super admin: `superadmin@aurora.test` / `ChangeMe123!` (override via `SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD`).

Deferred (by design): Sidekiq::Web dashboard, admin session persistence in the web app, httpOnly-cookie token hardening — revisited in later sprints.

### Sprint 3 — Navigation & Site Configuration ✅ (completed 2026-07-22)

Delivered:
- **DB:** `navigation_items` (self-referential, unlimited depth, visibility + scheduling), `site_settings` (jsonb, `public_read`), `feature_flags`.
- **Public APIs:** `GET /navigation?location=` (nested, Redis-cached, visible+live only), `GET /settings` (public map), `GET /feature_flags` (map).
- **Admin APIs (RBAC):** `navigation_items` CRUD + `reorder`; `site_settings` CRUD; `feature_flags` CRUD. New `navigation.read/manage` permissions.
- **Query/cache:** `Navigation::TreeBuilder` (single query, in-memory assembly, no N+1) + `Navigation::TreeCache` (REDIS_POOL, per-location keys, test-bypassed, busted on `after_commit`).
- **Frontend:** API-driven `MegaMenu` (desktop hover panels) + `MobileNav` (recursive `<details>` drawer) + brand name from `site.name`; header now fully server-fetches nav.
- **Seeds:** sample 3-level menu (Men/Women/Electronics/Sale), 5 settings, 4 flags.

Verification:
- Backend: **44 RSpec pass**, RuboCop clean, Brakeman 0; live `/navigation` returns nested 3-level tree, `/settings` exposes only public keys, `/feature_flags` maps correctly.
- Frontend: **14 Vitest pass**, tsc + ESLint clean, `next build` green; live desktop mega-menu renders `Men/Women/Electronics/Sale` from the API (screenshot), responsive mobile drawer.

Notes:
- Mega-menu UI renders the common 3 tiers; the data model + admin tree are unlimited-depth.
- SMTP wired this session (ADR-014): real Gmail delivery verified live (direct + via Sidekiq).
- Header SSR-fetches nav; statically-generated auth pages bake in build-time nav (empty if API is down at build — graceful). A proper ISR/revalidation strategy is a later performance refinement.

### Post-Sprint-3: Admin portal + real-click E2E hardening (2026-07-23)

- **Server-rendered admin portal** (ADR-015): `/admin` login (session), dashboard with live stats, sign-out. Backend root → `/admin` → login-or-dashboard, matching production admin behavior. Removed the earlier placeholder Next.js `/admin/login` page (admin belongs in Rails per spec).
- **Real-click integrated E2E** (browser-driven, live API) exercised the full customer auth loop (register → verify → login → logout → protected-route) plus the admin portal — inspecting actual network calls (all 2xx + CORS). Two real bugs surfaced that unit/request specs missed, both fixed:
  1. Base UI `Button` rendered as a `<Link>` needed `nativeButton={false}` (accessibility console error) — `verify-email`, `not-found`.
  2. `api_only` mode omits `Rack::MethodOverride`, so the admin `button_to method: :delete` sign-out 404'd — re-added the middleware; added a form-style (`_method`) logout spec.
- Also renamed `:unprocessable_entity` → `:unprocessable_content` app-wide (Rack 3 deprecation).

### Post-Sprint-3: Storefront header UX + blueprint (2026-07-23)

- **Header UX:** logged-out shows **Sign in** (link) + **Sign up** (button); logged-in shows an **avatar → account dropdown** (My account, Orders/Wishlist/Addresses gated to their sprints, Sign out inside). Both the mega-menu and account dropdown now hang **flush from the header's bottom border** (`h-16` trigger wrappers + `top-full`, `rounded-b-xl`, no top border).
- **[FEATURE_BLUEPRINT.md](FEATURE_BLUEPRINT.md)** added — 20-domain enterprise feature catalog (Amazon/Myntra/Nike-Apple/Shopify) with ✅/🟡/⬜/⭐ tags. It is the **depth standard** for every sprint.
- **Admin Settings area** (brought forward from Sprint 13): tabbed **Roles / Permissions / Team** at `/admin/settings`.
  - **Roles** — full CRUD (`Admin::RolesController`): create/edit/delete roles + toggle each role's permissions, gated behind `roles.manage` (Super Admin). Key is immutable after creation; system roles can't be deleted; a role assigned to admins can't be deleted.
  - **Permissions** — read-only catalog (each maps to an enforced code capability; not user-created).
  - **Team** — assign roles to admins, gated behind `users.manage`, with a self-lockout guard.
  - Portal permission helpers `allowed_to?`/`require_permission!` on the admin base controller. **17/17 admin specs.**
- **ROADMAP expanded to v2** (23 sprints): folded in all ⭐ areas — Promotions & Coupons, Loyalty/Wallet/Gift Cards, Personalization & Recommendations, Reviews & Q&A, Exchanges, advanced Payments (GST invoices, saved cards/EMI adapters), fulfillment/tracking, SEO/a11y, observability/GDPR. External gateways/carriers/SMS = adapters + mocks until keys provided; i18n/PWA marked optional.

### Sprint 4 — Catalog Core ✅ (completed 2026-07-23)

Delivered:
- **DB:** `brands`, `categories` (self-referential, unlimited depth, feeds nav via matching slugs), `tax_classes` (GST rate + HSN), `products` (lifecycle enum draft/active/archived + `published_at` scheduling, flags featured/new/best, `price_cents`/`mrp_cents`/currency, SEO, weight/dimensions/warranty, soft-delete), `product_images` (ordered, primary). `Sluggable` concern for slug generation.
- **Public APIs:** `GET /products` (paginated + filters: category-subtree, brand, q, price, sort — `Products::Query`), `GET /products/:slug`, `GET /categories` (nested tree), `GET /categories/:slug` (breadcrumb + children), `GET /brands`.
- **Admin APIs (RBAC):** products (nested image attrs, soft-delete/archive), categories, brands, tax classes CRUD — gated `products/categories/brands.manage`.
- **Storefront:** PLP (`/products`), category pages (`/c/[...slug]` — nested paths, breadcrumb, subcategory chips), PDP (`/products/[slug]` — gallery, price/discount, highlights, **Product JSON-LD** + dynamic SEO metadata), ProductCard/Grid/Pagination. Home "Shop the store" now links to the live catalog; nav category links resolve to real pages.
- **Seeds:** 3 tax classes, 4 brands, 11 categories (mirroring nav), 8 products with images/flags/prices.

Verification: backend **80 RSpec** pass, RuboCop clean, Brakeman 0; frontend **20 Vitest**, tsc + ESLint clean, `next build` green (11 routes); live E2E — `/products`, `/c/men` (4 subtree products), PDP all render with images (screenshots).

Deferred (noted): bulk CSV import/export, Active Storage **binary** uploads (images are URL-based now), interactive PDP gallery — land with admin-media/CMS work. Variants, attributes, inventory → Sprint 5.

### Post-Sprint-4: Admin customer + admin-user management (2026-07-24)

Brought forward (super-admin "manage everything"):
- **Customers** (`/admin/customers`, sidebar activated): searchable list, detail with **login sessions** (`refresh_tokens`: started/expires/IP/device/status), activate/deactivate account, revoke a single session or all active. Gated `customers.read` / `customers.manage`.
- **Admin users** (Settings → Team): create admin (email/name/password + roles), activate/deactivate, remove (soft-delete), assign roles. Gated `users.manage` (Super Admin) with self-action guards.
- Verification: **91 RSpec** (11 new), RuboCop clean, Brakeman 0; live — Customers list (5 accounts), customer detail (13 sessions for a test account), Team new-admin form all render.

### Post-Sprint-4: Admin catalog management UI + full-width layout (2026-07-24)

Addressed feedback ("no admin UI to manage categories", "tables should be full width", "edit customers", "can't see login sessions"):
- **Full-width layout**: removed the `.content { max-width: 1100px }` cap — admin content/tables now fill the viewport (measured 1192px content flush to the right edge at 1440px, vs the old 1100px). Broadened form-input styling to cover `number`/`datetime-local`/`select`/`textarea`.
- **Categories** (`/admin/categories`): full CRUD, hierarchical indented list (parent/position/visibility), soft-delete. Gated `categories.read`/`categories.manage`.
- **Brands** (`/admin/brands`): full CRUD + product count. Gated `brands.read`/`brands.manage`.
- **Products** (`/admin/products`): searchable paginated list; create/edit form with brand/category/tax selects, status, rupee↔cents price/MRP conversion, flags (featured/new/best), highlights (newline→array), image URLs (newline→`product_images`, first=primary), SEO + logistics. Gated `products.read`/`products.manage`.
- Sidebar restructured into **Catalog** (Products/Categories/Brands) + **Operations** (Customers/Orders/CMS) + Settings.
- **Customer edit** (`/admin/customers/:id/edit`): edit first/last name + phone (email stays customer-managed). Login-sessions panel confirmed visible full-width with an "Edit details" action.
- **Permissions page**: added a callout clarifying permissions are code-enforced capabilities — assign them via Roles → Team (not editable as a list).
- Verification: **103 RSpec** (12 new: catalog CRUD + rupee/image conversion + permission gating + customer edit), RuboCop clean, Brakeman 0; live real-click — created a nested category via the form (auto-slug, flash) and soft-deleted it; product edit form prefills price ₹89,999/status/brand/category/tax; category tree + products list render full-width.

### Post-Sprint-4: Reusable UI kit (both apps) (2026-07-24)

Extracted generic, reusable table / filters / pagination / tabs / modal on both sides so lists and dialogs stop being hand-rolled per screen.
- **Backend** (`app/views/admin/ui/`): `_table` (data-driven — columns carry `cell` lambdas), `_tabs` (link tabs), `_search` (search + filter `<select>`s, GET form), `_pagination` (Kaminari pager that carries all query params across pages), `_modal` (native `<dialog>`, opened via `data-modal-open`/`data-modal-close` wired globally in the layout). Refactored Settings tabs + Categories/Brands/Products/Customers lists to consume them; added a **status filter** to Products & Customers and a **confirm modal** for "Revoke all sessions". Deleted the old `admin/shared/_pagination`.
- **Frontend** (`src/components/ui/`): `DataTable<T>` (column config + `onRowClick`/empty state), `Pagination` (generic `createHref`; `catalog/pagination` now wraps it), `Tabs` (Base UI panel tabs) + `NavTabs` (link tabs, RSC-safe), `Dialog`/`DialogContent` (Base UI modal — focus trap, Esc, backdrop), `FilterBar` (URL-synced search + selects via the router, resets `page`). Wired `FilterBar` into the storefront PLP (search + sort) as a live example.
- Base UI notes: Tab active state is `state.active` / `data-active` (not `selected`); dialog transitions use `data-[starting-style]`/`data-[ending-style]`. Added `ResizeObserver`/`matchMedia` polyfills to `src/test/setup.ts` for Base UI under jsdom.
- Verification: BE **103 RSpec** / RuboCop clean (94 files) / Brakeman 0; live — Products status filter (`?status=draft` → empty, `?status=active` → 8), revoke-all modal opens over a dimmed backdrop. FE **35 Vitest** (15 new across the 5 components) / tsc / ESLint / production build all clean; live — storefront PLP FilterBar sorts price-ascending via `?sort=price_asc`.

### Post-Sprint-4: Admin-user sessions + Roles/Team on the UI kit (2026-07-24)

- **Admin-user login sessions** (the missing counterpart to customer sessions): each Team member now has a **detail page** (`/admin/settings/team/:id`) with Profile, a Roles editor, activate/remove, and a **Login sessions** panel (their API refresh tokens) with per-session Revoke + a "Revoke all" confirm modal. Role/status edits moved here from the inline Team row and redirect back to the detail. Gated `users.manage`. Note: portal (cookie) sign-ins are stateless and surface as `last_login_at`, not as individually-revocable rows — only API sessions are listed (stated on the page).
- **Shared sessions panel** `admin/ui/_sessions` (built on `_table` + the revoke modal) now powers BOTH the customer and admin-user detail pages — one implementation, two owners via `revoke_all_path` + a `revoke_path` lambda.
- **Roles** and **Team** lists retrofitted onto `admin/ui/_table` (column `cell` lambdas). Team is now display-only + a "Manage" link; the "+ New admin" form stays on the list.
- Verification: BE **107 RSpec** (4 new: admin detail renders sessions, revoke one/all, `users.manage` gating), RuboCop clean, Brakeman 0; live — Team table + Roles table render via `_table`; admin detail shows 2 seeded API sessions; real-click Revoke flipped a session to `revoked` (flash "Session revoked.").
- Left a demo admin `cat.manager@aurora.test` (role Admin, 2 API sessions) in the dev DB to exercise the sessions view — removable via Team → Manage → Remove admin.

### Post-Sprint-4: Permission editing (2026-07-24)

- **Permissions tab is now editable.** Each permission has an **Edit** page ([permissions/edit.html.erb](backend/app/views/admin/permissions/edit.html.erb)): editable **name + description**, **key locked** (it's the code contract), and a **role-assignment grid** (toggle which roles grant it — the mirror of editing from the Roles side). Keys can't be created/deleted (they map to enforced `#can?` checks). Gated by a new `permissions.manage` capability (super_admin only by default; excluded from the broad "admin" role like `roles.manage`).
- `Admin::PermissionsController#update` syncs role assignments but **never strips Super Admin's grant** (`keep = super_admin-currently-assigned + desired non-super roles`). Permissions list retrofitted to `admin/ui/_table` with a "Granted to roles" column (super_admin hidden as noise; shows "super admin only" when no other role has it). Settings-tabs active logic extended to the new controller.
- Verification: **113 RSpec** (7 permission specs: edit renders, update+sync, unassign, super_admin never-added, super_admin-preserved, gating), RuboCop clean (95 files), Brakeman 0; live real-click — granted `coupons.manage` to Support + edited its description, confirmed on the list, then reverted.

### Post-Sprint-4: Custom dropdown + async typeahead (scales to millions) (2026-07-24)

Native `<select>` popups are OS-controlled (macOS overlays the control; can't force open-below/fixed-height/scroll). Replaced with a progressive-enhancement custom dropdown ([_select_enhancer.html.erb](backend/app/views/admin/ui/_select_enhancer.html.erb) + `.ui-select*` in `_styles`): opens **below** the trigger, fixed **220px** max-height, **scrollable**, keeps the native `<select>` hidden as the form's source of truth. Two modes:
- **static** — options from the server-rendered `<select>`; a search box appears when >8 options (client-side filter). Auto-applied to every `main.content select`.
- Single-open: a shared `closers` registry means opening one dropdown closes any other (clicking a trigger `stopPropagation`s, so the outside-click handler alone wasn't enough). Verified: opening a 2nd closes the 1st; same-trigger toggles closed; outside-click closes.
- **async** (`data-endpoint`) — fetches the top 20 matches as the user types (250ms debounce) from `Admin::OptionsController` (`GET /admin/options/:resource`, SearchManager-backed, `.read`-gated, supports `exclude`). Never renders more than ~20 rows, so it **handles millions of records**. Wired to the product form's Brand + Category and the category form's Parent (self excluded); those `@brands`/`@categories`/`@parent_options` full loads were dropped.
- Verification: **130 RSpec** (4 new OptionsController specs), RuboCop clean (96 files), Brakeman 0; live — filter dropdown opens below (`panel.top ≥ trigger.bottom`), list `max-height:220px` + `overflow:auto`; product-form category typeahead `?q=shirt` → T-Shirts/Shirts, selecting upserts the option + sets `category_id=3` on the native select (form submits correctly).

### Post-Sprint-4: Config-driven per-page selector (2026-07-25)

- **Per-page dropdown** in every admin filter bar (`admin/ui/_search`): options `10 / 15 / 20 / 30 / 50`, auto-submits on change (via a `data-autosubmit` hook in the select enhancer), and the choice persists across pages (pager carries `per_page`).
- **Options come from the config model** — stored in `SiteSetting` (the typed jsonb config, `value_type`): `pagination.per_page_options` (json array) + `pagination.default_per_page` (number). Added `SiteSetting.get(key, default)` (typed, table-missing-safe) and a `PaginationHelper` (`per_page_options`/`default_per_page`/`current_per_page`) with hard-coded fallbacks. Changing the setting changes the dropdown + default with no code change.
- `SearchManager`'s default page size now reads `pagination.default_per_page` (per-model `per_page:` override → config default → `DEFAULT_PER_PAGE` constant).
- Verification: **145 RSpec**, RuboCop clean (121 files), Brakeman 0; live — products bar shows "10 / page" with the 5 options, `?per_page=15`→15 rows/4 pages, `?per_page=50`→50 rows/2 pages, selection persists.

### Post-Sprint-4: ID columns + search-by-id + list thumbnails (2026-07-24)

- **ID shown on every record screen**: leading **ID column** on all lists (Products, Customers, Categories tree+flat, Brands, Roles, Permissions, Team), plus `ID #<n>` in the sub-heading of every edit page (product/category/brand/role/permission/customer) and `ID: #<n>` in the Profile panel of the customer + admin-user detail pages.
- **Search by ID**: `SearchManager#apply_text_search` now OR-matches the primary key exactly when the query is purely numeric (alongside the text-column ILIKE), so typing an id finds that record. Works for every searchable list + facet counts.
- **List thumbnails**: Products (primary image), Brands (logo), Categories (image) show a 40×40 thumbnail in the name cell (dashed placeholder when none); products list eager-loads `:product_images` to avoid N+1, images `loading="lazy"`.
- Verification: **145 RSpec** (1 new: find-by-id), RuboCop clean; live — products list shows ID + thumbnails, `?q=8` matches by id/text; all six lists lead with an ID column.

### Post-Sprint-4: Image URL preview (thumbnail + link) on catalog forms (2026-07-24)

Reusable live preview widget ([admin/ui/_image_preview](backend/app/views/admin/ui/_image_preview.html.erb) + `_image_preview_script`): renders a 120×120 thumbnail plus the clickable URL (new tab) for each image URL in a bound field, re-rendering on every `input` — so it updates as URLs are typed or added by the uploader. Broken URLs show an "image unavailable" placeholder. Wired into the **product** form (image-URL list, multiple), **category** image, and **brand** logo. Verified live: product edit shows thumbnail + link per URL, both images loaded at 120px, links visible + `target=_blank`; adding a URL live-updates the previews; category/brand forms render the widget. 144 RSpec / RuboCop clean.

### Post-Sprint-4: Production hardening + dead-code cleanup (2026-07-24)

- **Removed dead dependency**: dropped the direct `image_processing` gem (was only for the abandoned Active Storage variants; still present transitively via CarrierWave, so no functional loss). Active Storage tables/migration were already rolled back.
- **Rate-limiting gaps closed** (rack-attack): added throttles for the **server-rendered portal login** (`POST /admin/login` — previously only the JSON API login was throttled), **media uploads** (`/admin/uploads`), **resend/verify-email**, and **reset-password** (token brute-force). Existing login/register/forgot-password limits retained.
- **Full green gate** (production baseline): backend **144 RSpec / RuboCop clean (183 files) / Brakeman 0**; frontend **39 Vitest / tsc / ESLint / production build** all clean. Live: admin + API boot clean and serve 200; upload still stores + serves.
- Note: remaining "production-ready" items are deployment-level (S3/Cloudinary creds, `SECRET_KEY_BASE`, host/SSL, log aggregation, monitoring) rather than code — the code surface is clean, gated by RBAC, throttled, and Brakeman-clean.

### Post-Sprint-4: Reusable CarrierWave upload system (2026-07-24)

Production-ready, provider-configurable file/media uploads (replaces the earlier Active-Storage spike, which was rolled back). Docs: [backend/docs/UPLOADS.md](backend/docs/UPLOADS.md).
- **Provider by config only** ([config/storage_provider.rb](backend/config/storage_provider.rb) + [carrierwave.rb](backend/config/initializers/carrierwave.rb)): `STORAGE_PROVIDER=local|aws|cloudinary`. `local` (disk `public/uploads`) is the default; `fog-aws` + `cloudinary` are bundled `require:false` and loaded lazily only when selected → zero code change to switch, no boot cost for local. Credentials from ENV → Rails credentials.
- **One `GenericUploader`** ([app/uploaders/generic_uploader.rb](backend/app/uploaders/generic_uploader.rb)) for the whole app — images/docs/pdf/csv/xls/ppt/video/audio/zip (extension + content-type allowlists), mountable (`mount_uploader`/`mount_uploaders`) or standalone. Cloudinary wired via a conditional `include`; storage engine (`:file`/`:fog`) chosen from `StorageProvider`. Standalone uploads land in a unique per-upload subdir (no collisions, keeps original filename).
- **`Media::Upload` service** (standalone GenericUploader + kind/size validation) → **`Admin::UploadsController`** (`POST /admin/uploads`) returns an absolute URL. Backs the reusable `admin/ui/_uploader` widget wired into product images (append/multiple), category image, brand logo.
- **Extensibility** (documented, no business-logic change to enable): thumbnails/variants (`version` blocks), Cloudinary transforms, background/direct uploads, CDN (`ASSET_HOST`), extra providers.
- Verification: **144 RSpec** (11 new: StorageProvider default/aws/cloudinary/fallback, Media::Upload store/reject-type/reject-size, endpoint 201+absolute-url/reject/auth), RuboCop clean (120 files), Brakeman 0; live — real multipart POST → 201 with absolute URL, stored file served at 200 (image/png); runtime local store writes `/uploads/media/YYYY/MM/<token>/<file>`.

### Post-Sprint-4: Auto-generated product SKU (2026-07-24)

Products no longer require a manually-entered SKU. `Product` gains `before_validation :generate_sku, if: -> { sku.blank? }` → `"SKU-" + SecureRandom.alphanumeric(8).upcase`, retried on collision (the DB unique index + `uniqueness` validation are the final guards); a manual SKU is still honoured. Form field is now optional with an "Auto-generated if blank" placeholder. Verified: **133 RSpec** (3 new — generates when blank, distinct across products, keeps a manual one), RuboCop clean, Brakeman 0; live — created a product with a blank SKU → got `SKU-VWARMLAL`.

### Post-Sprint-4: Custom-select refinements — single-open, searchable key, highlight, infinite scroll (2026-07-24)

Follow-ups on the custom dropdown:
- **Single-open**: a shared `closers` registry closes any other open dropdown when one opens (the trigger's `stopPropagation` had let multiple stay open). Verified: opening a 2nd closes the 1st; same-trigger toggles; outside-click closes.
- **`searchable` opt-in key**: the dropdown gains a search box when `data-searchable` is set (in addition to the >8-options auto-behaviour and async mode). The `admin/ui/_search` filter partial takes `searchable: true` per filter; enabled on the Products Brand/Category filters (which can reach 20 facet values).
- **Search-term highlight**: typed text is wrapped in `<mark class="ui-select-mark">` within each option (XSS-safe: label escaped, match wrapped). Works static + async. Verified: "shi" → "T-**Shi**rts"; "nov" → "**Nov**a (14)".
- **Infinite scroll (async)**: `Admin::OptionsController` now paginates (`PER_PAGE = 20`, returns `meta.next_page`); the dropdown loads the next page when the list scrolls near the bottom and appends (token guards stale searches; loading guard serialises pages). Seeded 26 extra brands (→30) to exercise it. Verified: endpoint page1=20/next_page:2, page2=10/next_page:null; Brand dropdown 21 options → scroll → 31.
- Verification: **130 RSpec**, RuboCop clean (96 files), Brakeman 0.

### Post-Sprint-4: Pagers show total item count (2026-07-24)

The pagers only showed "Page X of Y" and rendered nothing on single-page lists, so the **total count was invisible**. Both pagers now surface it:
- **Admin `admin/ui/_pagination`**: always renders (even single page) a left-aligned "Showing X–Y of N items" (from Kaminari `offset_value`/`limit_value`/`total_count`); Prev/Next + "Page X of Y" only when >1 page. `.pager` → `space-between`, added `.pager-nav`.
- **FE `ui/pagination`**: `PageMeta` gained optional `total_count`/`per_page`; shows "Showing X–Y of N" when present, else falls back to "Page X of Y".
- Verification: **126 RSpec** / RuboCop clean / Brakeman 0; FE **39 Vitest** (1 new range test) / tsc / lint; live — admin customers "Showing 1–10 of 30 items · Page 1 of 3", single-page Roles "Showing 1–6 of 6 items", storefront PLP page 2 "Showing 11–20 of 45".

### Post-Sprint-4: Generic SearchManager + per-page 10 + bulk seed (2026-07-24)

Adapted the `SearchManager` pattern from the `luxe-threads-backend` reference into an Aurora-native, Brakeman-safe concern ([search_manager.rb](backend/app/models/concerns/search_manager.rb)). A model declares `search_manager on: [...], aggs_on: [...], range_on: :col` and gets `Model.search(params, scope:)` → `Result(records:, facets:)`:
- **text search** (ILIKE across `on` columns via Arel `matches` — no string interpolation),
- **multi-value facet filters** (`aggs_on`; normalises enum keys→int, `*_id`→int, booleans, strings),
- **numeric range** (`range_on` + `min`/`max`),
- **disjunctive facet counts** with human labels (enum→humanized, `*_id`→association name, bool→Yes/No) — each facet ignores its own filter so options stay switchable.
- **facet cap** (`DEFAULT_FACET_LIMIT = 20`, per-model overridable via `facet_limit:`): high-cardinality columns are ranked by count and capped so dropdowns can't balloon; the currently-selected value is always kept even if it ranks past the cap; association names are resolved only for the chosen rows (not the full set). Filter selects get `max-width: 240px` + native scroll.
- **built-in pagination** (`page` + `per_page` params; `DEFAULT_PER_PAGE = 10`, `MAX_PER_PAGE = 100`, per-model overridable via `per_page:`): `search` returns a Kaminari-paginated `records` (ordering preserved from the passed scope) — portal controllers just use `result.records`. Opt out with `paginate: false` (the JSON API does this and builds its `meta` envelope via `Paginatable`). The `_pagination` partial carries `per_page` across page links.
Declared on `Product` (`on: name/sku/search_keywords`, `aggs_on: status/brand_id/category_id/featured/new_arrival/best_seller`, `range_on: price_cents`). Wired into the admin products list (portal + JSON API): search + **Status/Brand/Category filter dropdowns showing live counts** ("Active (45)", "Nova (14)"), facets returned under `meta.facets` on the API.
- **Default page size → 10** (`Paginatable::DEFAULT_PER_PAGE`; admin products/customers `.per(10)`).
- **Bulk seed**: `upsert_product` now takes `status:`; added 45 deterministic products (mostly active, some draft/archived) → 53 total / 45 live.
- Verification: **122 RSpec** (7 new SearchManager specs: text/facet/enum/range/labels/disjunctive/cap+selected-survival), RuboCop clean (95 files), Brakeman **0**; live — storefront PLP paginates 45 live products → "Page 1 of 5" @10/pg (page 2 loads); admin products → "Page 1 of 6" @10/pg with facet-count filters; `?status=draft`→5, `?status=active`→5 pages, `?q=phone`→8. (Public catalog PLP still uses `Products::Query` for slug/subtree resolution; only its page size changed.)

### Post-Sprint-4: Search + filters + pagination on every admin list (2026-07-24)

Rolled the `SearchManager` + `admin/ui/_search` + `admin/ui/_pagination` pattern across all admin lists for consistency (per-page 10):
- Declared `search_manager` on `Customer` (email/name/phone + status facet), `Brand` (name/slug), `AdminUser` (email/name + status facet), `Role` (name/key/description), `Permission` (key/name/description), `Category` (name/slug + visible facet).
- **Customers** — search + status facet (counts) + pagination (30 seeded → 3 pages). **Brands / Roles** — search + pagination. **Permissions** — search + pagination (33 → 4 pages). **Team** — search + status facet + pagination. **Products** — already done (facets).
- **Categories** (a tree) — default view stays the hierarchical tree with the level legend; when a search term or visibility filter is active it switches to a **flat, paginated** result set (depth-coloured dot via `ancestors`). Visibility filter uses fixed Visible/Hidden options.
- `SearchManager#facet_label` now humanizes plain-string facet values (e.g. status `active`→"Active").
- Seeded 25 more customers (mix of active/inactive, some unconfirmed) → 30 total.
- Verification: **122 RSpec**, RuboCop clean (95 files), Brakeman 0; live — customers "Page 1 of 3" + status facet "Active (26)/Inactive (4)"; permissions "Page 1 of 4"; `?status=inactive`→4, `?q=customer1`→11 (facets update disjunctively); categories `?q=shirt`→2 flat rows; brands/roles/team single-page with search present.

### Post-Sprint-4: Category list level indicators (2026-07-24)

UX: the `↳` arrow + indentation made depth hard to read as the tree grows. Replaced with a **coloured dot per level** (cycling palette), an explicit **`L{n}` badge** after each name, and a **legend under the title** mapping dot colour → Level. Removed the `↳`; kept indentation. Purely presentational (categories index + `_styles`). Verified live: legend shows Level 1–3, dots colour-match rows (Men=L1 indigo, Topwear=L2 teal, T-Shirts=L3 amber), no arrows; category specs still green.

### Post-Sprint-4: Fixed email-verification resend dead-end (2026-07-24)

Bug: if the activation link expired (2-day TTL), the user was stuck — expired link → `422 invalid_token`, login → `403 email_unconfirmed`, and `resendVerification()` existed in the API layer but was **never called by any UI**; register/verify pages told users to "sign in to resend" but signing in didn't resend. Backend was fine; the FE recovery path was missing.
Fix: new reusable [ResendVerification](frontend/src/components/auth/resend-verification.tsx) component (one-click when the email is known, email-input form otherwise; enumeration-safe neutral confirmation) wired into all three surfaces:
- **Login page** — on `email_unconfirmed`, shows "Your email isn't verified yet" + a one-click Resend (email already typed).
- **Register success** — real Resend button (uses the just-submitted email) instead of the misleading "sign in to resend" copy.
- **Verify-email failure** — email field + Resend for users landing from a dead link.
- Verification: FE **38 Vitest** (3 new: component preset/no-preset, login unconfirmed→resend), tsc/ESLint/build clean; live real-click on the storefront — unconfirmed login surfaced the resend box, clicking it re-armed the token (`confirmation_sent_at` reset, verified in DB); dead-link page shows the email+resend form.

### Post-Sprint-4: Uniform canonical category URLs (2026-07-24)

Bug: nav menu linked full paths (`/c/men/topwear/t-shirts`) but the category page's breadcrumbs/children emitted single-segment links (`/c/topwear`), so the same category had two URLs. Fixed [c/[...slug]/page.tsx](frontend/src/app/c/[...slug]/page.tsx): build a canonical `basePath` from the category's ancestor chain (`breadcrumb` = `Category#ancestors`, root-first) + its own slug, and use it for breadcrumb links (cumulative prefixes), child chips, and pagination. Added a redirect that normalises short/non-canonical URLs (e.g. `/c/topwear` → `/c/men/topwear`, query preserved) so each category has exactly one URL matching the nav. Verified live: breadcrumb Topwear → `/c/men/topwear`, children full-path, `/c/topwear?sort=price_asc` → `/c/men/topwear?sort=price_asc`. tsc/ESLint/build clean.

### Post-Sprint-4: One pagination component per stack (2026-07-24)

Consolidated so each stack reuses a single pager:
- **Backend**: already DRY — `admin/ui/_pagination` is rendered by the only two paginated lists (Products, Customers); nothing else hand-rolls a pager. API JSON pagination is the single `Paginatable` concern. No change needed.
- **Frontend**: collapsed the two-layer setup (pages → `catalog/pagination` adapter → `ui/pagination` primitive) into **one** component. `ui/pagination.tsx` now takes the app-standard `{ meta, path, query }` interface (carries filters across pages, hides itself on a single page) via a local `PageMeta` type (no coupling to the API module). Deleted `catalog/pagination.tsx`; PLP + category pages import `@/components/ui/pagination` directly.
- Verification: FE **35 Vitest** (pager test rewritten for the meta interface: single-page hide, query-carrying prev/next, disabled bounds), tsc + ESLint + build clean; live — storefront PLP renders (pager correctly absent with 8 seeded products = 1 page).

### Post-Sprint-4: New-admin form moved to its own page (2026-07-24)

UX: the inline `<details>` "New admin" form on Settings → Team didn't scale as the team grows. Replaced it with a **dedicated page** (`/admin/settings/team/new`, `SettingsController#new_admin`), matching the catalog + roles pattern — Team list now shows a "+ New admin" toolbar button. Create failures re-render the standalone page with errors; Team tab stays active on it. Removed the dead `details.new-admin` CSS and simplified `load_team`. Verified: **115 RSpec** (2 new: page renders, invalid re-renders), RuboCop clean, Brakeman 0; live real-click — created an admin via the new page (flash + row) and cleaned it up.

### Authorization architecture (ADR: Pundit removed 2026-07-24)

Authorization is a **permission-key RBAC layer**, not Pundit: `AdminUser#can?(key)` (roles → role_permissions → permissions; super_admin bypass), invoked via `authorize_permission!(key)` in the `AdminAuthentication` concern (JSON API) and `require_permission!(key)` in `Admin::BaseController` (ERB portal).

Pundit was installed with only a deny-by-default `ApplicationPolicy` stub (no concrete policies, no `authorize`/`policy_scope` calls) — dead scaffolding. **Removed** (gem + `app/policies/` + `include Pundit::Authorization` in `Api::V1::BaseController` + the `Pundit::NotAuthorizedError` rescue + unused `handle_forbidden`). Rationale: `can?` covers capability checks; Pundit only earns its keep for record-scoped rules (`policy?`/`policy_scope`), which first appear at Sprint 9 (orders) — re-introduce it deliberately then. Verified: boots, 113 RSpec, RuboCop clean (94 files), Brakeman 0, API + portal both 200 after `bundle` + server restart.

### Sprint 5 — Variants, Attributes & Inventory ✅ (completed 2026-07-25)

Delivered across four phased, individually-gated commits:

- **DB (8 tables):** `product_attributes` + `attribute_values` (attribute registry with filterable/searchable flags), `product_variants` + `variant_option_values` (variants as unique option combinations), `product_specifications`, `inventory_items` (on_hand/reserved/low_stock_threshold/backorderable), `stock_movements` (immutable ledger), `product_relations` (related/recommended/cross/up-sell). **Master-variant pattern**: every product owns a hidden option-less master variant carrying default price + inventory until real options exist; backfilled for all pre-existing products via a data migration. Cart/checkout (Sprint 8/9) can therefore always reference a variant.
- **Services (`Inventory::`):** `AdjustStock` (signed on-hand delta + ledger, negative-guard), `Reserve`/`Release` (reservation **foundation** — move qty in/out of `reserved` with an oversell guard; TTL expiry deferred to cart). `HasSku` concern extracted (Product + ProductVariant).
- **Curated admin portal:** Attributes manager (`/admin/attributes`, nested value editor), per-product **Variants** management (`/admin/products/:id/variants` — option pickers, price/SKU/stock), a dedicated **Inventory** screen (`/admin/inventory` — search, low-stock filter + count, availability badges, per-variant adjust + threshold/backorder settings + full movement history), and Specifications + Related-products panels on the product edit page. Sidebar gains Attributes + Inventory. Gated `products.*` / `inventory.*`.
- **Public API:** PDP (`GET /products/:slug`) extended with `options` (selector), `variants` (price/stock/combo), `in_stock`, `total_available`, `price_range`, `specifications`, `related_products`; option-less products expose their master. N+1-safe eager loading. (PLP availability facets deferred to Sprint 7.)
- **Storefront:** client-side variant selector (`ProductBuyBox`) — option buttons resolve the matching variant, live price + stock ("In stock" / "Only N left" / "Out of stock"); Specifications table; "You may also like" related rail; JSON-LD availability now reflects real stock.
- **Seeds:** Color/Size attributes, a Color×Size variant matrix on two apparel products with a mixed stock profile (out/low/healthy), specs, related links, and stocked masters — all idempotent.

Verification: backend **207 RSpec** (44 model/service + 21 admin + 3 PDP-API), RuboCop clean (229 files), Brakeman 0; frontend **43 Vitest** (4 new buy-box), tsc + ESLint + `next build` clean; live real-click — created an attribute (with a dynamically-added value), inventory screen shows option chips + badges, PDP variant selection flips price 899↔999 + stock. **Gotcha fixed:** dynamically-added nested-attribute rows must use a numeric child index (Rails strong-params silently drops non-integer keys).

Deferred (by design): reservation TTL-expiry job (→ cart/checkout), low-stock **email** alerts (→ Sprint 15 Notifications), PLP availability facet (→ Sprint 7), barcode scanning / backorder-preorder UX (⭐).

### Post-Sprint-5: catalog/UX enhancements (2026-07-27)

Follow-ups after Sprint 5, each committed + gated green:
- **Category-scoped attributes** — a `category_attributes` join lets each category declare which variant attributes apply (inherited down the tree); the variant form offers only those, falling back to all when unset. Enables per-type sizes (shirts S/M/L vs shoe UK numbers). Seeds link Color + Size to apparel.
- **Product form completeness** — added `dimensions` (L×W×H) input; create now lands on the edit page so variants/inventory/related can be added immediately.
- **Global Variants list** (`/admin/variants`) with filters (brand, category, per-option Color/Size, active, stock). Cross-table lists use a scoped query (SearchManager is own-column only).
- **Remove (✕) buttons** on every attribute-value & spec row.
- **Storefront**: real homepage (hero, category tiles, New Arrivals/Best Sellers rails, value props) replacing the Sprint-1 status page; mega menu renders **any depth** recursively.
- **Menu = Categories tree (ADR-016)** — retired the `navigation_items` subsystem entirely (table/model/API/services/specs/seeds/permissions on the backend; `getNavigation`/schemas on the frontend). The header now builds the menu from the visible category tree via `getMenuTree()`. Managed in the admin Categories section.
- **Cleanup** — removed dead health-status FE code and junk dev test data (test categories/product, demo admin accounts).

Gates after all of the above: backend **205 RSpec / RuboCop clean (223 files) / Brakeman 0**; frontend **40 Vitest / tsc / ESLint / next build** clean.

### Sprint 6 — CMS & Homepage ✅ (completed 2026-07-28)

Delivered across 4 phased commits (backend d89d3f7 → 8a2ef06, frontend 04ebd46):
- **DB (4 tables):** `banners` (hero/promo/announcement, visible + schedule window), `homepage_sections` (block registry: `section_type` + jsonb `config`), `static_pages` (slug + SEO), `footer_sections` (heading + jsonb links). New `Schedulable` concern (visible + [starts_at, ends_at] → `.live`).
- **Aggregation:** `Cms::Homepage` composes homepage blocks (resolved per type: hero→banners, product_rail→live products, category_grid→roots, rich_text→body), the announcement, and the footer.
- **Curated admin** (`cms.read`/`cms.manage`, new "Content" sidebar group): Banners, Homepage sections (type + config editor), Pages (search + status), Footer (repeatable links) — full CRUD.
- **Public API:** `GET /homepage` (sections), `GET /site` (announcement + footer), `GET /pages/:slug` (published page, 404 otherwise).
- **Storefront:** homepage composed from CMS sections (section renderer, graceful fallback); site-wide announcement bar + dynamic footer from `/site` (fetched once in the layout); static pages at `/p/[slug]` with SEO. Removed the interim hardcoded homepage layout.
- **Seeds:** announcement + 2 hero banners, 4 homepage sections, 3 footer columns, 6 static pages.

Verification: backend **226 RSpec / RuboCop clean (246 files) / Brakeman 0**; frontend **42 Vitest / tsc / ESLint / next build** clean; live — homepage renders announcement + hero + category grid + New Arrivals/Best Sellers from the CMS, footer columns render, /p/about + /p/shipping render.

### Sprint 7 — Search & Discovery ✅ (completed 2026-07-28)

Delivered one-by-one (backend d6cbd22, 9e59bab; frontend 3f9a21b, f459f7b, 80c471a, 0d5317e, 460c4e9, f4cd613):
- **Faceted filters** (`Products::Search`): cross-table brand / attribute / availability / price filters + facet counts against a browse context; scalable filter sidebar (dropdown-per-facet, collapse, show-more cap, in-group search). Category filter intentionally excluded (menu covers it).
- **Category-scoped size split:** numeric `Waist (in)` for jeans vs alpha `Size` for tops — separate attributes, scoped per category so facets resolve the right scale.
- **Variant-option images:** `product_images.attribute_value_id` binds an image to an option value (colour); PDP gallery swaps on selection. Interactive gallery: thumbnail-swap + hover-magnify.
- **Infinite scroll** on listings (IntersectionObserver sentinel + "Load more" fallback; synchronous cursor + id-dedupe; replaced pagination).
- **Recently-viewed** rail (localStorage + `useSyncExternalStore`, PDP).
- **No-result recommendations** ("Popular right now" featured fallback on empty listings/search).
- **Search autocomplete** (debounced header typeahead reusing the products endpoint) + **query synonyms** (tee↔t-shirt, jeans↔denim, …).
- **Storefront icons** (value props, search, account menu, clear filters).

Deferred (perf/infra, by design — no user-facing gap at current scale):
- **Full-text `tsvector`** search — ROADMAP defers this ("or dedicated later"); current `ILIKE` + synonyms also preserves the typeahead's partial-match UX that a naïve tsvector switch would regress.
- **Redis facet caching** — facet counts are computed per request (instant at current catalog size); caching would add invalidation complexity for no visible benefit yet.

Verification: backend RSpec (search specs incl. synonyms) / RuboCop clean; frontend **58 Vitest / tsc / ESLint / next build** clean; live — faceted filtering, waist-vs-size per category, variant image swap + hover-zoom, infinite scroll (45 products, 0 dupes), recently-viewed rail, no-result recs, header typeahead, synonym search all verified.
