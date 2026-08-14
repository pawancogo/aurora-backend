# frozen_string_literal: true

# Roadmap seed data — the detailed Sprint/SprintFeature backfill for the admin
# Roadmap tracker (/admin/sprints). Kept in its own file (loaded from
# db/seeds.rb) because it's long-form content, not app configuration.
#
# Each feature carries two audiences on purpose:
#   description             — plain language: what it does + exactly where to
#                              go click on it. Written for PMs/stakeholders who
#                              have never opened the codebase.
#   technical_description   — implementation detail: which files/classes/
#                              tables/services are involved and how they fit
#                              together. Written for engineers picking this up.

SPRINTS = [
  { number: 1, title: "Foundation & Infrastructure", status: "completed",
    goal: "Docker Compose stack, health checks, CI, and the base Rails + Next.js skeleton.",
    estimate: "3 days",
    features: [
      { area: :backend, title: "Health/readiness endpoints",
        description: "<p>The app can report whether it's up, and separately whether the things it depends on (like the cache) are actually reachable — this is what monitoring tools and load balancers ping to know if the site is healthy.</p><p><strong>Where to see it:</strong> there's no admin screen for this — it's a machine-to-machine check. Open <code>http://localhost:3001/api/v1/health</code> in a browser and you'll get a small JSON response confirming the API is alive; <code>/api/v1/ready</code> additionally fails (503) if Redis is down.</p>",
        technical_description: "<p><code>Api::V1::HealthController#show</code> (liveness, always 200 if the process is running) and <code>#ready</code> (readiness — calls <code>Health::ReadinessCheck</code>, which pings Redis and returns 503 on failure). Both return the standard <code>{ data, meta }</code> envelope (ADR-006). Routes: <code>GET /api/v1/health</code>, <code>GET /api/v1/ready</code>.</p>" },
      { area: :backend, title: "Sample Sidekiq job",
        description: "<p>Background work (things too slow to make a shopper wait for) can run on a separate worker process, either right away or scheduled for later — the foundation every later \"send an email\" / \"process an order\" feature builds on.</p><p><strong>Where to see it:</strong> nothing user-facing yet at this sprint — it's plumbing. You'd only notice it indirectly, e.g. verification emails (Sprint 2) arriving via a background job instead of blocking the register request.</p>",
        technical_description: "<p>A demo job under Sidekiq (Redis-backed queue) proving both the immediate (<code>.perform_async</code>) and scheduled/delayed (<code>.perform_in</code>) enqueue paths work end-to-end against the real Redis instance, not just in a test double.</p>" },
      { area: :frontend, title: "Homepage SSR + live health pill",
        description: "<p>The homepage renders on the server (fast first paint, good for SEO) and shows a small live status indicator confirming it can actually talk to the backend — an easy visual gut-check that the two halves of the stack are wired together correctly.</p><p><strong>Where to see it:</strong> open the storefront at <code>http://localhost:3000</code> — the status pill was part of the very first placeholder homepage, later replaced by the real CMS-driven homepage in Sprint 6.</p>",
        technical_description: "<p>Server component fetches <code>/api/v1/health</code> via TanStack Query on the client for live updates; CORS had to be configured on the Rails side (<code>config/initializers/cors.rb</code>) for the cross-origin browser fetch from :3000 to :3001 to succeed.</p>" },
      { area: :other, title: "Docker Compose + CI",
        description: "<p>Anyone on the team can bring up the entire stack (database, cache, API, background worker, web app) with a single command instead of installing five things by hand — and every pull request gets automatically checked (tests, linters, security scan) before it can be merged.</p><p><strong>Where to see it:</strong> not a UI feature — look at <code>docker-compose.yml</code> in the backend repo root, and the checks tab on any pull request on GitHub.</p>",
        technical_description: "<p><code>docker-compose.yml</code> defines db/redis/api/sidekiq/web services; <code>.github/workflows/ci.yml</code> runs RSpec/RuboCop/Brakeman (backend) and Vitest/tsc/ESLint/build (frontend) on every push. Compose is authored but not runtime-verified in this dev environment (no Docker daemon available) — verified instead by running each process natively.</p>" }
    ] },
  { number: 2, title: "Authentication & RBAC", status: "completed",
    goal: "Customer + admin authentication with rotating JWT refresh tokens, and role-based access control.",
    dependencies: "Sprint 1", estimate: "4 days",
    features: [
      { area: :database, title: "Auth + RBAC tables",
        description: "<p>The system has two completely separate kinds of accounts — shoppers and staff — and a flexible way to say exactly which tools each staff member is allowed to use, without hard-coding \"managers can do X\" into the code.</p><p><strong>Where to see it:</strong> Admin → Settings → Team (who's on staff) and Admin → Settings → Roles (what each role can do). There's no direct \"tables\" screen — this is the data model underneath those two pages.</p>",
        technical_description: "<p>Seven tables: <code>customers</code>, <code>admin_users</code>, <code>roles</code>, <code>permissions</code>, <code>role_permissions</code> (join), <code>admin_user_roles</code> (join, an admin can hold multiple roles), <code>refresh_tokens</code> (polymorphic <code>owner</code> — used by both customers and admins).</p>" },
      { area: :backend, title: "Customer auth flow",
        description: "<p>A shopper can create an account, confirm their email address, sign in, stay signed in across visits without re-entering a password every time, and recover access if they forget their password — all without ever risking their password leaking, and without letting an attacker figure out which emails have accounts (a common privacy leak in \"forgot password\" flows).</p><p><strong>Where to see it:</strong> storefront <code>/register</code> → <code>/verify-email</code> (auto-logs you in) → <code>/login</code> → <code>/forgot-password</code> / <code>/reset-password</code>.</p>",
        technical_description: "<p><code>Auth::RegisterCustomer</code>, <code>Auth::VerifyEmail</code>, <code>Auth::AuthenticateCustomer</code>, <code>Auth::RotateRefreshToken</code>, <code>Auth::RequestPasswordReset</code>/<code>Auth::ResetPassword</code> (all under <code>app/services/auth/</code>) — enumeration-safe (same response whether or not the email exists), tokens hashed before storage, refresh tokens single-use with rotation (ADR-010).</p>" },
      { area: :backend, title: "Admin auth + RBAC",
        description: "<p>Staff sign in through a completely separate door from shoppers, and once in, each person only sees the tools their role grants — an inventory clerk can't touch site settings, for instance.</p><p><strong>Where to see it:</strong> <code>/admin/login</code>, then try visiting a section your current role doesn't have — you'll be redirected with a permission error. Super Admin (the seeded <code>superadmin@aurora.test</code> account) can see everything.</p>",
        technical_description: "<p><code>Auth::AuthenticateAdmin</code> + <code>AdminUser#can?(key)</code> (roles → role_permissions → permissions, super_admin bypasses every check). API enforcement via <code>authorize_permission!</code> in the <code>AdminAuthentication</code> concern; portal (ERB) enforcement via <code>require_permission!</code> in <code>Admin::BaseController</code>. 30 permissions across 6 seeded roles (see <code>db/seeds.rb</code>).</p>" },
      { area: :frontend, title: "Auth pages + protected routes",
        description: "<p>All the screens a shopper needs to manage their own account, and a guarantee that account-only pages (like order history) simply aren't reachable if you're not signed in — you get bounced to the login page instead of seeing an error or, worse, someone else's data.</p><p><strong>Where to see it:</strong> try visiting <code>/account</code> while signed out — you're redirected to <code>/login</code>. Sign in and it works.</p>",
        technical_description: "<p><code>AuthProvider</code> context wraps the app; an axios interceptor catches 401s and silently retries once after a token refresh. Next.js middleware (<code>src/middleware.ts</code>) gates <code>/account/*</code> at the edge before the page even renders.</p>" }
    ] },
  { number: 3, title: "Navigation & Site Configuration", status: "completed",
    goal: "API-driven navigation menu, site settings, and feature flags.",
    dependencies: "Sprint 1, Sprint 2", estimate: "3 days",
    features: [
      { area: :database, title: "Navigation/settings/flags tables",
        description: "<p>The site's top menu, general settings (like the store name and currency), and on/off feature switches can all be changed by staff without anyone touching code or redeploying.</p><p><strong>Where to see it:</strong> the menu itself is what you see across the top of the storefront. Store-wide settings and flags aren't exposed as their own admin screen yet in this sprint — they surface later once the relevant admin UI is built.</p>",
        technical_description: "<p>Originally a self-referential <code>navigation_items</code> table (unlimited depth, visibility + scheduling) plus <code>site_settings</code> (jsonb, typed) and <code>feature_flags</code>. <strong>Superseded by ADR-016</strong> (2026-07-27): <code>navigation_items</code> was later retired entirely — the storefront menu is now generated directly from the visible <code>categories</code> tree, one less thing to keep in sync. <code>site_settings</code>/<code>feature_flags</code> are still in active use (e.g. <code>pagination.per_page_options</code>, the <code>wishlist</code> flag).</p>" },
      { area: :backend, title: "Redis-cached navigation tree",
        description: "<p>The menu loads instantly for every shopper, no matter how large the category tree grows, because the site doesn't rebuild it from scratch on every single page view.</p><p><strong>Where to see it:</strong> not directly visible — you'd only notice its absence (a slow-loading header) if it weren't there.</p>",
        technical_description: "<p>Historically <code>Navigation::TreeBuilder</code> (single query, in-memory tree assembly, no N+1) + <code>Navigation::TreeCache</code> (Redis, per-location keys, busted on <code>after_commit</code>). Retired with <code>navigation_items</code> under ADR-016 — the menu now comes from <code>Category</code> queries directly, which is cheap enough at current catalog size that a dedicated cache layer hasn't been reintroduced.</p>" },
      { area: :frontend, title: "Mega menu + mobile nav",
        description: "<p>Desktop shoppers get a hover-out panel menu; mobile shoppers get a slide-out drawer — both driven by the same underlying menu data, so staff only ever manage one thing.</p><p><strong>Where to see it:</strong> storefront header — hover a top-level category on desktop, or tap the hamburger icon on a narrow/mobile viewport.</p>",
        technical_description: "<p><code>src/components/navigation/mega-menu.tsx</code> (desktop hover panels, any depth via recursion) and <code>src/components/navigation/mobile-nav.tsx</code> (recursive <code>&lt;details&gt;</code> drawer, no JS framework needed for the expand/collapse). Both now render the Categories tree (ADR-016), not the original <code>navigation_items</code> API.</p>" },
      { area: :admin, title: "Server-rendered admin portal",
        description: "<p>Staff get a dedicated dashboard and sign-in, completely separate from the customer-facing storefront — this is the very first version of the admin area every later sprint builds screens into.</p><p><strong>Where to see it:</strong> <code>/admin</code> — redirects to <code>/admin/login</code> if signed out, or the dashboard if signed in.</p>",
        technical_description: "<p><code>Admin::DashboardController</code>, <code>Admin::SessionsController</code> — session/cookie-authenticated (ADR-015), distinct from the stateless JWT <code>/api/v1/admin/*</code> API used elsewhere. Required re-adding <code>Rack::MethodOverride</code> + Cookies/Session/Flash middleware to the otherwise api-only Rails app.</p>" }
    ] },
  { number: 4, title: "Catalog Core", status: "completed",
    goal: "Products, categories, brands, and tax classes with a public storefront catalog and admin CRUD.",
    dependencies: "Sprint 1", estimate: "5 days",
    features: [
      { area: :database, title: "Catalog tables",
        description: "<p>The store has an actual product catalog — items organised into categories and brands, each automatically taxed at the right rate for what it is.</p><p><strong>Where to see it:</strong> Admin → Products / Categories / Brands (the management screens); Storefront → any category or product page (the result).</p>",
        technical_description: "<p><code>brands</code>, self-referential <code>categories</code> (unlimited depth, slugs feed the storefront nav), <code>tax_classes</code> (GST rate + HSN code), <code>products</code> (lifecycle enum draft/active/archived, scheduled <code>published_at</code>, feature flags, price in cents, SEO fields, soft-delete), <code>product_images</code> (ordered, one marked primary). <code>Sluggable</code> concern generates URL-safe slugs.</p>" },
      { area: :backend, title: "Public + admin catalog APIs",
        description: "<p>Shoppers can browse and search the catalog from the storefront; staff can create, edit, and reorganise products, categories, and brands from the admin — the same underlying data, two very different audiences.</p><p><strong>Where to see it:</strong> public side: <code>/products</code> on the storefront. Staff side: Admin → Products (or Categories/Brands).</p>",
        technical_description: "<p>Public: <code>GET /products</code> (paginated, filterable by category-subtree/brand/price/sort via <code>Products::Query</code>), <code>GET /products/:slug</code>, nested <code>GET /categories</code>. Admin: RBAC-gated (<code>products.manage</code> etc.) CRUD controllers under <code>Api::V1::Admin::</code> and the ERB portal.</p>" },
      { area: :frontend, title: "PLP, category pages, PDP",
        description: "<p>The actual pages a shopper uses to find and evaluate a product — a browsable list, a category page with a breadcrumb trail, and a detail page with photos, price, and the information needed to decide to buy.</p><p><strong>Where to see it:</strong> <code>/products</code> (listing), <code>/c/men</code> or any category slug (category page), <code>/products/:slug</code> (product detail).</p>",
        technical_description: "<p>Product listing + category pages with breadcrumb + subcategory chips; PDP includes an image gallery, price/discount display, highlights list, Product JSON-LD structured data, and dynamic per-product SEO <code>&lt;meta&gt;</code> tags.</p>" },
      { area: :admin, title: "Admin catalog + team management UI",
        description: "<p>Staff get one place to manage the entire product catalog, plus manage their own team's accounts and customer accounts — the first real \"back office\" experience in the admin.</p><p><strong>Where to see it:</strong> Admin → Products/Categories/Brands (catalog), Admin → Customers, Admin → Settings → Team.</p>",
        technical_description: "<p>Full CRUD for products (nested image attributes, soft-delete/archive)/categories/brands; customer + admin-user management with a login-sessions panel (<code>admin/ui/_sessions</code> partial); the first reusable UI-kit pieces (table/search/pagination/modal/uploader under <code>app/views/admin/ui/</code>) that every later admin screen, including the Sprint-9 Roadmap tracker, builds on.</p>" }
    ] },
  { number: 5, title: "Variants, Attributes & Inventory", status: "completed",
    goal: "Product variants (option combinations), attributes, specifications, and inventory tracking.",
    dependencies: "Sprint 4", estimate: "5 days",
    features: [
      { area: :database, title: "Variant + inventory tables",
        description: "<p>A single product can now come in multiple colours/sizes, each tracked as its own thing with its own price and stock count — and the store always knows exactly how many of each it has on hand, with a full history of every stock change.</p><p><strong>Where to see it:</strong> Admin → Products → open a product → Variants tab; Admin → Inventory (stock levels + history across everything).</p>",
        technical_description: "<p>8 tables: <code>product_attributes</code>/<code>attribute_values</code> (the attribute registry — e.g. Colour, Size), <code>product_variants</code>/<code>variant_option_values</code> (a variant is a unique option combination), <code>product_specifications</code>, <code>inventory_items</code> (on_hand/reserved/low_stock_threshold), <code>stock_movements</code> (append-only ledger — never edited, only added to), <code>product_relations</code>. Master-variant pattern: every product gets a hidden, option-less variant by default so cart/checkout always has a variant to reference even before real options exist.</p>" },
      { area: :backend, title: "Inventory services",
        description: "<p>Stock counts stay accurate even when many people are buying the same item at the same time — the store never sells something it doesn't actually have.</p><p><strong>Where to see it:</strong> Admin → Inventory → adjust a variant's stock and watch the movement history update.</p>",
        technical_description: "<p><code>Inventory::AdjustStock</code> (signed on_hand delta + ledger entry, guards against going negative), <code>Inventory::Reserve</code>/<code>Inventory::Release</code> (moves quantity in/out of <code>reserved</code> with an oversell guard — the foundation the Sprint-9 checkout flow builds its stock-decrement logic on).</p>" },
      { area: :admin, title: "Attributes, Variants, Inventory screens",
        description: "<p>Staff can define what options a product comes in (colours, sizes), set up each variant's price/stock, and keep an eye on what's running low across the whole catalog.</p><p><strong>Where to see it:</strong> Admin → Attributes (define Colour/Size), Admin → Products → [a product] → Variants, Admin → Inventory (search + low-stock filter + per-variant adjustment history).</p>",
        technical_description: "<p>Nested attribute-value editor, per-product variant management (option pickers + price/SKU/stock), and a dedicated Inventory screen (search, low-stock filter + count, availability badges, per-variant adjust + threshold settings + full movement history).</p>" },
      { area: :frontend, title: "Variant selector on PDP",
        description: "<p>Shoppers pick a colour and size right on the product page and immediately see the price and \"in stock\"/\"only 3 left\" status update for that exact combination — no page reload, no guessing.</p><p><strong>Where to see it:</strong> any product with variants, e.g. <code>/products/slim-fit-jeans</code> — click a colour swatch or size button.</p>",
        technical_description: "<p><code>ProductBuyBox</code> component — client-side option buttons resolve the matching <code>ProductVariant</code> from the PDP payload and update price/stock text live; also renders the specifications table and a \"you may also like\" related-products rail.</p>" }
    ] },
  { number: 6, title: "CMS & Homepage", status: "completed",
    goal: "Fully CMS-driven homepage and promotional content.",
    dependencies: "Sprint 4", estimate: "4 days",
    features: [
      { area: :database, title: "CMS tables",
        description: "<p>The homepage, promotional banners, and footer are all made of content blocks that staff control directly — nobody needs to ask a developer to change a homepage banner.</p><p><strong>Where to see it:</strong> Admin → Content (Banners / Homepage / Pages / Footer).</p>",
        technical_description: "<p><code>banners</code> (hero/promo/announcement placements), <code>homepage_sections</code> (a typed block registry — hero/product_rail/category_grid/rich_text — with a jsonb <code>config</code> column per type), <code>static_pages</code>, <code>footer_sections</code>. New <code>Schedulable</code> concern gives any of these a visible flag + optional [starts_at, ends_at] window.</p>" },
      { area: :backend, title: "Homepage aggregation",
        description: "<p>The homepage assembles itself fresh from whatever content blocks staff currently have turned on — turn a section off in the admin, and it disappears from the live site immediately.</p><p><strong>Where to see it:</strong> storefront <code>/</code> — turn a homepage section off in Admin → Content → Homepage and refresh the storefront to see it vanish.</p>",
        technical_description: "<p><code>Cms::Homepage</code> (<code>app/services/cms/homepage.rb</code>) composes each block by type (hero → live banners, product_rail → live products, category_grid → root categories, rich_text → stored body) plus the site-wide announcement bar and footer, exposed via <code>GET /homepage</code>.</p>" },
      { area: :admin, title: "Content management screens",
        description: "<p>Marketing/content staff get dedicated screens to manage every piece of homepage and site content — banners, homepage sections, static pages, and the footer — all with full create/edit/delete.</p><p><strong>Where to see it:</strong> Admin → Content → Banners / Homepage / Pages / Footer.</p>",
        technical_description: "<p>Full CRUD controllers + views for Banners, Homepage sections (with a type + jsonb-config editor), Pages (search + status), Footer (repeatable link groups) — gated by new <code>cms.read</code>/<code>cms.manage</code> permissions, under a new \"Content\" sidebar group.</p>" },
      { area: :frontend, title: "Dynamic homepage",
        description: "<p>The homepage is no longer a static placeholder — it's a real, editable page with a rotating hero banner, category shortcuts, and product rails, all coming from what staff configured.</p><p><strong>Where to see it:</strong> storefront <code>/</code>.</p>",
        technical_description: "<p>Real homepage replacing the Sprint-1 placeholder status page — hero carousel, category tiles, New Arrivals/Best Sellers rails, value props — all rendered from <code>Cms::Homepage</code>'s output rather than hard-coded JSX.</p>" }
    ] },
  { number: 7, title: "Search & Discovery", status: "completed",
    goal: "Faceted search, filtering, infinite scroll, and discovery features across the storefront.",
    dependencies: "Sprint 4, Sprint 5", estimate: "5 days",
    features: [
      { area: :backend, title: "Faceted filters",
        description: "<p>Shoppers can narrow a product list by brand, size/colour, price range, and availability all at once, and see how many results each filter option would leave before even clicking it.</p><p><strong>Where to see it:</strong> storefront <code>/products</code> or any category page — the filter sidebar, with a live count next to each option.</p>",
        technical_description: "<p><code>Products::Search</code> (<code>app/services/products/search.rb</code>) — cross-table brand/attribute/availability/price filters with disjunctive facet counts against the current browse context. Category itself is deliberately excluded from the facet list since the menu already covers it.</p>" },
      { area: :frontend, title: "Infinite scroll listings",
        description: "<p>Product lists load more items automatically as a shopper scrolls down, instead of forcing a click to \"page 2\" — a smoother, more modern browsing feel.</p><p><strong>Where to see it:</strong> storefront <code>/products</code> — scroll to the bottom of the grid and watch the next page load in.</p>",
        technical_description: "<p><code>IntersectionObserver</code>-driven sentinel + a \"Load more\" fallback button; a synchronous cursor plus id-based de-duplication guards against double-loading a page. Replaced the earlier numbered-pagination component on catalog listings specifically (admin lists kept pagination).</p>" },
      { area: :frontend, title: "Variant-option gallery images",
        description: "<p>Picking a colour on a product page swaps the photos to show that exact colour, instead of leaving shoppers staring at a picture of the wrong variant.</p><p><strong>Where to see it:</strong> a product with colour options, e.g. the demo jeans (SKU <code>CAT-045</code>) — click a colour swatch and watch the gallery change; hover an image to magnify.</p>",
        technical_description: "<p><code>product_images.attribute_value_id</code> binds a photo to a specific option value (e.g. \"Red\"); the PDP gallery filters to the selected colour's images. Interactive gallery also supports thumbnail-click-to-swap and hover-to-magnify.</p>" },
      { area: :frontend, title: "Recently-viewed + no-result recommendations",
        description: "<p>Shoppers see a strip of products they recently looked at (handy for comparing or coming back to something), and when a search turns up nothing, they get useful suggestions instead of a dead-end empty page.</p><p><strong>Where to see it:</strong> visit a few product pages, then open another PDP — the \"Recently viewed\" rail appears. Search for something nonsensical on <code>/products?q=zzznotreal</code> to see the \"Popular right now\" fallback.</p>",
        technical_description: "<p><code>src/lib/recently-viewed.ts</code> (localStorage) + <code>src/components/catalog/recently-viewed.tsx</code> (<code>useSyncExternalStore</code> for cross-tab consistency), rendered on the PDP. No-result state falls back to a featured-products rail rather than a blank page.</p>" },
      { area: :frontend, title: "Search autocomplete + synonyms",
        description: "<p>The header search box suggests matching products as you type, and understands that shoppers use different words for the same thing (\"tee\" and \"t-shirt\", \"jeans\" and \"denim\") so a search never comes up empty just because of word choice.</p><p><strong>Where to see it:</strong> storefront header search box — start typing \"tee\" and watch suggestions appear; try \"denim\" and confirm jeans show up.</p>",
        technical_description: "<p><code>src/components/layout/search-box.tsx</code> — debounced typeahead reusing the <code>/products</code> endpoint. Query synonym expansion (tee↔t-shirt, jeans↔denim, …) lives server-side in <code>Products::Search</code> so the same synonym logic covers both the typeahead and a full search submit.</p>" }
    ] },
  { number: 8, title: "Cart & Wishlist", status: "completed",
    goal: "Shopping cart and wishlist functionality.",
    dependencies: "Sprint 6, Sprint 2", estimate: "4 days",
    features: [
      { area: :backend, title: "Cart merge on login",
        description: "<p>If a shopper adds items to their cart before signing in and then signs in (or creates an account), those items are still there afterwards — nothing gets silently lost, which is exactly the kind of thing that quietly costs sales if it's broken.</p><p><strong>Where to see it:</strong> as a guest, add something to the cart, then log in (or register) — the mini-cart badge should keep the item.</p>",
        technical_description: "<p><code>CartMerging</code> concern, included in <code>Customer::SessionsController#create</code> and the email-verify auto-login path — folds the guest cart (identified by the <code>X-Cart-Token</code> header) into the now-signed-in customer's cart via <code>Carts::Manager#merge</code>, summing quantities for any shared variant. A related security fix scoped the guest-cart lookup to <code>customer_id: nil</code> so a stale token left in a browser after logout can't resolve to a since-claimed customer's cart.</p>" },
      { area: :backend, title: "Wishlist",
        description: "<p>Signed-in shoppers can save products they're interested in for later, separate from their cart — a \"maybe next time\" list rather than a \"buying now\" list. Guests don't get a wishlist; they're prompted to sign in first.</p><p><strong>Where to see it:</strong> sign in, then click the heart icon on any product → <code>/account/wishlist</code>.</p>",
        technical_description: "<p><code>wishlist_items</code> table (customer + product, unique pair) + <code>Api::V1::WishlistsController</code> (<code>GET /wishlist</code>, <code>POST /wishlist/items</code>, <code>DELETE /wishlist/items/:product_id</code>). Deliberately signed-in-only, matching the ROADMAP scope (no anonymous wishlist).</p>" },
      { area: :frontend, title: "Cart page + mini-cart",
        description: "<p>Shoppers get both a full cart page for reviewing everything in detail, and a quick-glance mini-cart from the header for a fast \"what's in my cart\" check without leaving the page they're on.</p><p><strong>Where to see it:</strong> click the cart icon in the header for the mini-cart popover, or go to <code>/cart</code> for the full page.</p>",
        technical_description: "<p><code>CartProvider</code> context (mirrors <code>AuthProvider</code>'s pattern) + <code>lib/api/cart.ts</code>. <code>/cart</code> page has line items, a quantity stepper, remove, and subtotal. The header mini-cart (<code>src/components/layout/cart-trigger.tsx</code>) is portaled to <code>document.body</code> to escape a `backdrop-filter` ancestor that would otherwise clip it, and uses wheel/touchmove interception rather than `overflow:hidden` to lock background scroll (the latter broke the header's sticky positioning).</p>" },
      { area: :frontend, title: "Wishlist heart toggle",
        description: "<p>A heart icon shows up on every product — on the listing grid and on the product page — letting a shopper save or un-save it with one click, with the heart instantly filling in or emptying so there's no doubt it worked.</p><p><strong>Where to see it:</strong> hover any product card (top-right corner heart) or open a PDP (heart near the buy box).</p>",
        technical_description: "<p>Reusable <code>WishlistButton</code> component — \"overlay\" variant for the product-card corner badge, \"inline\" variant for the PDP buy box. Optimistic UI update with rollback if the API call fails; redirects a signed-out shopper to <code>/login</code> instead of attempting the toggle.</p>" },
      { area: :backend, title: "Pagination + infinite scroll + DOM cap",
        description: "<p>Even a shopper with a huge cart or wishlist gets a page that loads fast and scrolls smoothly — the app never tries to render thousands of rows at once, which would slow the browser to a crawl.</p><p><strong>Where to see it:</strong> only visible with a large cart/wishlist (20+ items) — the mini-cart shows \"View cart for all N items\" past 20, and the full cart/wishlist pages show \"Showing the first 200\" past that.</p>",
        technical_description: "<p>Cart and wishlist <code>items</code> paginate server-side (<code>page</code>/<code>per_page</code>); <code>item_count</code>/<code>subtotal</code> come from the model's own full-table SQL aggregates rather than summing whatever page of items the serializer was handed, so totals stay correct regardless of pagination. Frontend caps rendered rows at 200 (cart/wishlist pages) and 20 (mini-cart) — a hard DOM-size ceiling on top of the server pagination, since infinite scroll alone doesn't bound how many nodes end up in the DOM.</p>" }
    ] },
  { number: 9, title: "Checkout & Order Placement", status: "completed",
    goal: "Complete checkout flow with immutable order address snapshots.",
    dependencies: "Sprint 8, Sprint 2", estimate: "4 days",
    features: [
      { area: :database, title: "Order tables",
        description: "<p>Every placed order keeps a permanent, unchangeable record of exactly what was bought, at what price, and delivered to which address — even if the product is later renamed, repriced, or deleted, and even if the shopper later edits their saved address. History never silently changes.</p><p><strong>Where to see it:</strong> Admin → Orders → open any order → the nested items table and address are the frozen snapshot, not a live link to the current product/address.</p>",
        technical_description: "<p><code>orders</code>, <code>order_items</code> (snapshots product name/sku/options/price at placement), <code>order_addresses</code> (a form-captured snapshot — deliberately <strong>not</strong> a foreign key to a persisted address book, since the canonical Customer Profile & Address Book sprint hadn't shipped yet), <code>shipping_methods</code>.</p>" },
      { area: :backend, title: "Checkout service",
        description: "<p>Placing an order is one safe, all-or-nothing step: the store double-checks that prices and stock haven't changed since the item was added to the cart, reserves the inventory, and empties the cart — if anything goes wrong partway through, nothing is left half-done.</p><p><strong>Where to see it:</strong> storefront <code>/checkout</code> → fill the form → \"Place order\" — the cart empties and you land on the order confirmation in one step.</p>",
        technical_description: "<p><code>Checkout::PlaceOrder</code> (<code>app/services/checkout/place_order.rb</code>) — re-validates every cart line (price/stock may have moved since it was added), snapshots items + shipping address, decrements on-hand inventory capped at what's truly available (never pushed negative), and destroys the cart_items, all inside one DB transaction.</p>" },
      { area: :backend, title: "Customer orders API",
        description: "<p>Shoppers can check out and later look back at everything they've ordered. There's no guest checkout by design — since a guest's cart already merges into their account the moment they sign in (Sprint 8), the flow is simply \"sign in, then check out,\" not \"check out anonymously.\"</p><p><strong>Where to see it:</strong> <code>/checkout</code> (place an order), <code>/account/orders</code> (history), <code>/account/orders/[id]</code> (a single order's detail).</p>",
        technical_description: "<p><code>GET /shipping_methods</code> (public), <code>POST /checkout</code>, <code>GET /orders</code> (paginated history), <code>GET /orders/:id</code> — all customer-JWT-authenticated, no anonymous access.</p>" },
      { area: :admin, title: "Admin orders (read-only)",
        description: "<p>Staff can look up any order placed on the store — search by order number, filter by status, and drill into the exact items and address on a specific order. This sprint's admin view is look-but-don't-touch; updating an order's status or fulfilling it is a later sprint.</p><p><strong>Where to see it:</strong> Admin → Orders (list with search + status filter) → click any order for the detail view.</p>",
        technical_description: "<p><code>Admin::OrdersController</code> list/detail, built on the existing <code>_search</code>/<code>_table</code>/<code>_pagination</code> UI-kit partials from Sprint 4 — status facet, search by order number, nested order-items table on the show page. <code>orders.read</code>/<code>orders.manage</code> permissions already existed in the seed file from earlier sprints, so no new permission plumbing was needed.</p>" },
      { area: :frontend, title: "Checkout flow + order history",
        description: "<p>The actual screens a shopper uses to buy something: enter a delivery address, pick a shipping speed, review what's in the cart and the total cost, place the order, and afterwards find it again in their order history.</p><p><strong>Where to see it:</strong> <code>/checkout</code> (single-page form: address → shipping method → item review → summary → place order), <code>/account/orders</code> (paginated history, same infinite-scroll pattern as the cart/wishlist), <code>/account/orders/[id]</code> (detail page, which doubles as the post-checkout confirmation screen).</p>",
        technical_description: "<p>RHF+Zod address form matching the register-page pattern; shipping method radios; item review + running total. The cart page's old \"Checkout — Sprint 9\" disabled placeholder link is now real, and <code>UserMenu</code>'s Orders link is de-flagged.</p>" }
    ] },
  { number: 10, title: "Payments (Razorpay)", status: "completed",
    goal: "Real payment gateway integration — checkout only confirms an order once payment is actually verified.",
    dependencies: "Sprint 9", estimate: "4 days",
    features: [
      { area: :backend, title: "Razorpay account + credentials",
        description: "<p>The store can accept real payments through Razorpay, starting in a safe test mode that never touches real money.</p><p><strong>Where to see it:</strong> not a UI feature — it's account setup on razorpay.com plus <code>RAZORPAY_KEY_ID</code>/<code>RAZORPAY_KEY_SECRET</code> in the backend's local <code>.env</code>.</p>",
        technical_description: "<p><code>config/initializers/razorpay.rb</code> calls <code>Razorpay.setup</code> from ENV when both are present (mirrors the SMTP-creds pattern, ADR-014) — checkout raises a clear error instead of an SDK exception if payments aren't configured yet.</p>" },
      { area: :database, title: "Payments table",
        description: "<p>The store keeps a record of every payment attempt on an order — whether it succeeded, failed, and how much was charged.</p><p><strong>Where to see it:</strong> Admin → Orders → open an order → \"Payment attempts\" panel.</p>",
        technical_description: "<p><code>payments</code> table: <code>razorpay_order_id</code>/<code>razorpay_payment_id</code>/<code>razorpay_signature</code>, <code>amount_cents</code>, status enum (created/authorized/captured/failed/refunded), raw payload. One row per Order — a retry reopens the same row rather than creating a new one.</p>" },
      { area: :backend, title: "Checkout now reserves stock and starts a real payment",
        description: "<p>Placing an order no longer confirms it instantly — the order is saved and inventory is held for it, but it only becomes a confirmed sale once payment actually goes through.</p><p><strong>Where to see it:</strong> place an order at <code>/checkout</code> — it shows as \"Awaiting payment\" in your order history until you pay.</p>",
        technical_description: "<p><code>Checkout::PlaceOrder</code> creates the order as <code>pending</code>, reserves inventory via <code>Inventory::Reserve</code> (built in Sprint 5, unused until now) instead of decrementing on-hand directly, and opens a <code>Razorpay::Order</code> for the total.</p>" },
      { area: :backend, title: "Payment verification + webhook safety net",
        description: "<p>The store double-checks with Razorpay that a payment is genuine before treating an order as paid, so a tampered or fake \"success\" can't slip through.</p><p><strong>Where to see it:</strong> after paying, the order flips to \"Confirmed\"; if payment fails, it shows \"Payment failed\" with a button to try again.</p>",
        technical_description: "<p><code>Checkout::VerifyPayment</code> (primary path, called by the frontend post-checkout) verifies the HMAC signature server-side; <code>Api::V1::WebhooksController</code> (signature-verified via the raw request body) is a safety net for when the browser closes before that call fires. Both funnel into <code>Checkout::ApplyPaymentOutcome</code> — idempotent, so whichever path arrives first wins.</p>" },
      { area: :frontend, title: "Razorpay Checkout widget + retry payment",
        description: "<p>Shoppers pay through Razorpay's own secure payment screen (cards, UPI, etc.) right after placing an order, and can pick up where they left off if a payment doesn't go through the first time.</p><p><strong>Where to see it:</strong> <code>/checkout</code> → \"Place order\" opens the payment widget; a stuck order's detail page (<code>/account/orders/[id]</code>) shows a \"Complete payment\" button.</p>",
        technical_description: "<p><code>src/lib/razorpay.ts</code> lazy-loads Checkout.js only when needed. The Key Secret never reaches the browser — only the public Key ID + a Razorpay order id, returned in <code>OrderSerializer</code>'s <code>payment</code> block while an order is <code>pending</code>.</p>" },
      { area: :backend, title: "Admin-configurable payment methods config",
        description: "<p>Staff can restrict which payment methods show up in the Razorpay widget (e.g. a Dashboard config limiting shoppers to cards + UPI, or opening up wallets/EMI) without any code change or redeploy — and if nothing's been configured, checkout still works, falling back to a safe card+UPI-only default.</p><p><strong>Where to see it:</strong> Admin → Payment settings — paste in a Razorpay Dashboard \"payment methods config\" ID and save. It applies to every order placed from then on.</p>",
        technical_description: "<p>Reuses the existing generic <code>SiteSetting</code> store (jsonb, typed, dotted key) rather than a new table — key <code>razorpay.config_id</code>. Edited via <code>Admin::PaymentSettingsController</code> (singleton show/update, gated by <code>settings.manage</code>). Threaded into <code>OrderSerializer#payment_json</code> as <code>razorpay_config_id</code> and passed to Razorpay Checkout.js's <code>config</code> option in <code>openRazorpayCheckout</code> (<code>src/lib/razorpay.ts</code>), which falls back to the hardcoded <code>CARD_UPI_ONLY_CONFIG</code> object whenever the setting is blank. The Orders API itself has no such parameter — this is purely a Checkout.js widget option.</p>" }
    ] },
  { number: 11, title: "Order Fulfillment & Cancellation", status: "completed",
    goal: "A real post-payment order lifecycle (Confirmed → Accepted → Ready to ship → Shipped → Delivered) with a one-click admin action to advance it, plus a genuine customer-facing cancellation flow.",
    dependencies: "Sprint 9, Sprint 10", estimate: "2 days",
    features: [
      { area: :database, title: "Expanded order status lifecycle",
        description: "<p>An order's status now reflects what's actually happening to the shipment, not just whether it's been paid for — Confirmed, Accepted, Ready to ship, Shipped, Delivered, in that order — so staff and shoppers always know exactly where an order stands.</p><p><strong>Where to see it:</strong> the status chip on any order, both on the storefront's order detail page and Admin → Orders.</p>",
        technical_description: "<p><code>Order</code>'s <code>status</code> enum (plain integer column, no DB constraint) gained <code>accepted</code> (new integer key <code>9</code>, appended rather than renumbering) and renamed <code>packed</code> → <code>ready_to_ship</code> (kept key <code>2</code> — nothing had ever set that status, so renaming outright was safe). <code>Order::FULFILLMENT_SEQUENCE</code> lists the forward order; <code>#next_status</code> walks it one step from the order's current status.</p>" },
      { area: :backend, title: "Admin \"advance one step\" fulfillment action",
        description: "<p>Moving an order forward through its lifecycle is a single button click — \"Mark as Accepted\", then \"Mark as Ready to ship\", and so on — deliberately not a free-form status dropdown, so a step can't be skipped or an order accidentally sent backwards. Available right from the orders list, not just inside each order, so staff can process a queue of orders without opening every single one.</p><p><strong>Where to see it:</strong> Admin → Orders — the button showing the next status sits inline on each row, and again on the order detail page; it disappears once the order reaches Delivered (or is Cancelled).</p>",
        technical_description: "<p><code>PATCH /admin/orders/:id/advance</code> → <code>Admin::OrdersController#advance</code> calls <code>order.update!(status: order.next_status)</code>, gated by the <code>orders.manage</code> permission (view-only <code>orders.read</code> can look but not advance). No-ops with a flash alert once <code>next_status</code> is <code>nil</code>. The same button renders both on <code>admin/orders/index.html.erb</code> (an extra table column, added only when the signed-in admin has <code>orders.manage</code>) and <code>admin/orders/show.html.erb</code>.</p>" },
      { area: :backend, title: "Real order cancellation (customer-facing)",
        description: "<p>A shopper can cancel their own order themselves — but only while it's still Pending or Confirmed. Once staff have accepted it for fulfillment it's too late to self-serve cancel (staff can still do it — see the next feature), and any stock being held for the order is freed immediately on cancellation.</p><p><strong>Where to see it:</strong> storefront → Account → Orders → open a Pending or Confirmed order — a \"Cancel order\" button appears; it's gone on any order that's moved further along.</p>",
        technical_description: "<p><code>Order#cancel!</code> (guarded by the pre-existing but previously-unused <code>cancellable?</code>/<code>CANCELLABLE_STATES = %w[pending confirmed]</code>) releases each item's reserved inventory via <code>Inventory::Release</code> inside a transaction, then sets <code>status: :cancelled</code> and <code>cancelled_at</code>. Exposed via <code>POST /api/v1/orders/:id/cancel</code>; the frontend's <code>cancelOrder()</code> (<code>src/lib/api/orders.ts</code>) calls it, and a 422 comes back with a clear error if the order has already moved past Confirmed.</p>" },
      { area: :backend, title: "Admin cancel/reject action (more leeway than shoppers)",
        description: "<p>Staff can cancel or reject an order themselves at any point up until it's shipped — including one they've already Accepted or marked Ready to ship — for reasons a shopper can't self-serve (stock turned out to be wrong, a fraud check failed, etc.). Once an order has actually shipped, cancelling it isn't safe to do with a click any more — that needs a proper return, not a cancellation.</p><p><strong>Where to see it:</strong> Admin → Orders → open any order that isn't yet Shipped — a red \"Cancel order\" link sits next to the advance button, with a confirmation prompt before it commits.</p>",
        technical_description: "<p><code>Order::ADMIN_CANCELLABLE_STATES</code> extends the customer-facing <code>CANCELLABLE_STATES</code> with <code>accepted</code>/<code>ready_to_ship</code>. <code>Order#admin_cancel!</code> shares the same inventory-release + <code>cancelled_at</code> logic as <code>#cancel!</code> (factored into a private <code>#perform_cancel!</code>). Exposed via <code>PATCH /admin/orders/:id/cancel</code> → <code>Admin::OrdersController#cancel</code>, gated by <code>orders.manage</code>.</p>" },
      { area: :backend, title: "Manual payment refund flow",
        description: "<p>When a cancelled order had already been paid for, the system flags that money as owed back to the shopper — but never sends it back on its own. A staff member with payments access has to review it and click \"Refund payment\" themselves before anything actually moves, and the order stays visibly marked \"Refund pending\" the whole time so it can't get missed — on the orders list as well as the order's own page, and filterable there too.</p><p><strong>Where to see it:</strong> Admin → Orders — a cancelled order that had a captured payment shows a \"Refund pending\" chip both in the list and on its own page, plus a \"Refund payment (₹X)\" button on the order page; the payment attempts table shows the same status plus the Razorpay refund ID and date once it's done. The list's \"Any refund status\" filter narrows it down to just the orders still waiting on one.</p>",
        technical_description: "<p><code>Payment</code> gained a <code>refund_pending</code> status (alongside the existing created/authorized/captured/failed/refunded) plus <code>razorpay_refund_id</code>/<code>refunded_at</code> columns (migration <code>AddRefundFieldsToPayments</code>). <code>Order#perform_cancel!</code> flags any <code>captured</code> payment as <code>refund_pending</code> — nothing else. The actual money movement lives in <code>Payments::Refund</code>, called only from <code>PATCH /admin/orders/:id/refund</code> → <code>Admin::OrdersController#refund</code>, gated by the <code>payments.manage</code> permission (deliberately separate from <code>orders.manage</code> — an Order Manager can cancel but not refund; only Admin/Super Admin hold <code>payments.manage</code> by default). Calls <code>Razorpay::Refund.create(payment_id:, amount:)</code> and records the result; a real Razorpay error (e.g. an unknown payment id) surfaces as a flash alert and leaves the payment <code>refund_pending</code> rather than silently succeeding. <code>Admin::OrdersController#index</code> filters to it via a plain <code>WHERE id IN (subquery)</code> against <code>Payment.refund_pending</code> (params[:refund_pending]) rather than a join, so it composes cleanly with the existing status facet counts.</p>" }
    ] },
  { number: 12, title: "Order Tracking UI", status: "completed",
    goal: "A visual fulfillment tracker on the storefront order page, matching the step-by-step tracking shoppers expect from any e-commerce order page.",
    dependencies: "Sprint 11", estimate: "half day",
    features: [
      { area: :frontend, title: "Order fulfillment stepper",
        description: "<p>A shopper's order page shows a horizontal progress tracker — Confirmed, Accepted, Ready to ship, Shipped, Delivered — with a checkmark on everything already done and the current step highlighted, the same pattern used by most e-commerce order-tracking pages. A cancelled, refunded, or returned order shows a plain one-line status instead of the tracker, and an order still awaiting payment shows neither (the existing \"complete payment\" box already covers that case).</p><p><strong>Where to see it:</strong> storefront → Account → Orders → open any order that's been confirmed.</p>",
        technical_description: "<p><code>OrderStepper</code> (<code>src/components/orders/order-stepper.tsx</code>) mirrors <code>Order::FULFILLMENT_SEQUENCE</code> from the backend as a plain client-side array — deliberately not fetched from an API, since the sequence is fixed and rarely changes. A sibling <code>hasOrderStepper(status)</code> helper lets the order page skip rendering the wrapping card entirely for pending/payment_failed orders instead of showing an empty box.</p>" }
    ] },

  # --- Not started yet — placeholders so the tracker shows the full plan, not just history.
  # Numbered by delivery order (continuing from 12), not ROADMAP.md's canonical numbering —
  # each goal notes which canonical ROADMAP.md sprint it corresponds to; see that file's own
  # "Sprint-numbering note" for why the two numbering schemes diverge. No features listed
  # (nothing to demo yet) — each gets its feature list filled in as it's actually built.
  { number: 13, title: "Customer Profile & Address Book", status: "planned",
    goal: "Profile editing and a real, reusable address book (add/edit/delete, default, Home/Office/Other) — separate from the one-off address a shopper types at checkout. Corresponds to canonical ROADMAP.md Sprint 8. Only a read-only /account stub exists today; checkout's own OrderAddress is a form-captured snapshot that never depended on this existing, which is why it shipped first.",
    dependencies: "Sprint 2", estimate: "1 week",
    features: [] },
  { number: 14, title: "Payment Methods Expansion & GST Invoicing", status: "planned",
    goal: "Beyond the working Razorpay integration (Sprint 10): pluggable payment-method adapters (saved cards, UPI, EMI, COD) and GST invoice PDF generation per order. Corresponds to the deeper scope of canonical ROADMAP.md Sprint 11.",
    dependencies: "Sprint 10", estimate: "1–2 weeks",
    features: [] },
  { number: 15, title: "Promotions & Coupons", status: "planned",
    goal: "Coupon codes, cart/product-level discount rules, flash sales, free-shipping thresholds. Corresponds to canonical ROADMAP.md Sprint 12. Nothing built yet — no coupon model, no discount engine.",
    dependencies: "Sprint 9 (Checkout)", estimate: "1–2 weeks",
    features: [] },
  { number: 16, title: "Loyalty, Wallet & Gift Cards", status: "planned",
    goal: "Points/tiers loyalty program, a store-credit wallet ledger, and purchasable/redeemable gift cards. Corresponds to canonical ROADMAP.md Sprint 13. Nothing built yet.",
    dependencies: "Sprint 15 (Promotions)", estimate: "1–2 weeks",
    features: [] },
  { number: 17, title: "Delivery, Shipments & Carrier Tracking", status: "planned",
    goal: "Real shipment records tied to a carrier/AWB adapter (mocked until a real courier is wired in), a customer-facing tracking page beyond the current status stepper, and a full address-change audit trail. Corresponds to canonical ROADMAP.md Sprint 14 — the internal status-advancement work already shipped (Sprint 11/12 here) covers the *order* side of fulfillment, not real shipment/carrier tracking.",
    dependencies: "Sprint 11 (Order Fulfillment)", estimate: "1–2 weeks",
    features: [] },
  { number: 18, title: "Returns, Refunds & Exchanges (post-delivery)", status: "planned",
    goal: "Customer-initiated return requests after delivery, admin approve/reject, reverse pickup, exchanges, and refund-to-store-credit as an alternative to the original payment method. Corresponds to canonical ROADMAP.md Sprint 15. What already shipped (Sprint 11 here) only covers pre-shipment cancellation and refunding a cancelled order's original payment — not a post-delivery return/exchange flow.",
    dependencies: "Sprint 11 (Order Fulfillment), Sprint 17 (Shipments)", estimate: "1–2 weeks",
    features: [] },
  { number: 19, title: "Reviews, Ratings & Q&A", status: "planned",
    goal: "Verified-purchase product reviews with photos, moderation queue, and product Q&A. Corresponds to canonical ROADMAP.md Sprint 16. The `reviews.read`/`reviews.manage` admin permissions are already seeded in anticipation of this, but no Review model or UI exists yet.",
    dependencies: "Sprint 4 (Catalog), Sprint 9 (Checkout — for verified-purchase)", estimate: "1 week",
    features: [] },
  { number: 20, title: "Personalization & Recommendations", status: "planned",
    goal: "Recently-viewed tracking, behavioral recommendation slots on PDP/homepage, and event tracking to power them. Corresponds to canonical ROADMAP.md Sprint 17. Today's \"related products\" is a static admin-curated relation, not personalization.",
    dependencies: "Sprint 7 (Search & Discovery)", estimate: "1–2 weeks",
    features: [] },
  { number: 21, title: "Notifications & Communications", status: "planned",
    goal: "Transactional emails for every order-lifecycle event (placed, confirmed, shipped, delivered, cancelled, refunded), SMS/push adapters (mocked), an in-app notification center, and shopper communication preferences. Corresponds to canonical ROADMAP.md Sprint 18. Nothing sends today — order/cancel/refund actions have no accompanying email.",
    dependencies: "Sprint 9 (Checkout), Sprint 11 (Order Fulfillment)", estimate: "1 week",
    features: [] },
  { number: 22, title: "Admin Ops: Bulk Import/Export & Audit Log Viewer", status: "in_progress",
    goal: "The bulk of canonical ROADMAP.md Sprint 19 (full admin CRUD for catalog/orders/customers/CMS/roadmap) already shipped organically across earlier sprints. What's left: bulk import/export (CSV) for catalog data, and a dedicated audit-log viewer — every model already has a full PaperTrail history sitting in the database, but there's no admin screen to browse it.",
    dependencies: "Sprint 4, Sprint 10, Sprint 11", estimate: "3–4 days",
    features: [] },
  { number: 23, title: "Analytics, Reports & Funnels", status: "planned",
    goal: "Sales/inventory reports, conversion funnels, and search/returns analytics dashboards. Corresponds to canonical ROADMAP.md Sprint 20. PaperTrail gives raw audit data (see Sprint 22) but no reporting layer exists on top of it yet.",
    dependencies: "Sprint 22 (Audit Log Viewer)", estimate: "1 week",
    features: [] },
  { number: 24, title: "SEO & Accessibility Hardening", status: "in_progress",
    goal: "Per-product SEO meta tags and Product JSON-LD structured data already shipped as part of Catalog Core (Sprint 4). Still missing, from canonical ROADMAP.md Sprint 21: dynamic XML sitemaps, redirect management, and a WCAG AA accessibility audit across both storefront and admin.",
    dependencies: "Sprint 4 (Catalog Core)", estimate: "1 week",
    features: [] },
  { number: 25, title: "Performance & Security Hardening", status: "planned",
    goal: "A dedicated caching strategy (today only navigation-adjacent reads are cache-conscious), N+1 audit across the whole app, CSP headers, and observability (Sentry/APM). Corresponds to canonical ROADMAP.md Sprint 22. RuboCop/Brakeman already run every change as a baseline, but this sprint is the formal pass beyond that.",
    dependencies: "All prior sprints", estimate: "1 week",
    features: [] },
  { number: 26, title: "Production Readiness & Kubernetes", status: "planned",
    goal: "Kubernetes manifests, production Docker images, secrets management, and a real CI/CD deploy pipeline. Corresponds to canonical ROADMAP.md Sprint 23. Docker Compose exists for local dev only (and per Sprint 1's own notes, was authored but never runtime-verified in this environment, which has no Docker daemon) — nothing here is production-shaped yet.",
    dependencies: "Sprint 25 (Performance & Security)", estimate: "1 week",
    features: [] }
].freeze

SPRINTS.each do |attrs|
  sprint = Sprint.find_or_initialize_by(number: attrs[:number])
  sprint.assign_attributes(attrs.slice(:title, :goal, :status, :dependencies, :estimate))
  sprint.save!

  attrs[:features].each_with_index do |feature, index|
    record = sprint.sprint_features.find_or_initialize_by(title: feature[:title])
    record.assign_attributes(area: feature[:area], description: feature[:description],
                              technical_description: feature[:technical_description], position: index)
    record.save!
  end
end

Rails.logger.info("Seeded #{Sprint.count} sprints / #{SprintFeature.count} sprint features (roadmap)")
