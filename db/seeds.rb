# frozen_string_literal: true

# Idempotent seeds: RBAC permissions, roles, and a bootstrap super admin.
# Safe to run repeatedly (find_or_create_by).

# `db:prepare` auto-seeds a freshly created database, which would flood the
# RSpec-managed test database with demo data and break test isolation.
return if Rails.env.test?

PERMISSIONS = {
  "dashboard.read" => "View dashboard",
  "users.read" => "View admin users",
  "users.manage" => "Create, update, and deactivate admin users",
  "roles.read" => "View roles",
  "roles.manage" => "Create, update, and delete roles",
  "permissions.read" => "View permissions",
  "permissions.manage" => "Edit permission descriptions and their role assignments",
  "products.read" => "View products",
  "products.manage" => "Create, update, and delete products",
  "categories.read" => "View categories",
  "categories.manage" => "Manage categories",
  "brands.read" => "View brands",
  "brands.manage" => "Manage brands",
  "inventory.read" => "View inventory",
  "inventory.manage" => "Adjust inventory",
  "orders.read" => "View orders",
  "orders.manage" => "Update order status and details",
  "payments.read" => "View payments",
  "payments.manage" => "Manage payments and refunds",
  "coupons.read" => "View coupons",
  "coupons.manage" => "Manage coupons",
  "reviews.read" => "View reviews",
  "reviews.manage" => "Moderate reviews",
  "cms.read" => "View CMS content",
  "cms.manage" => "Manage CMS content",
  "customers.read" => "View customers",
  "customers.manage" => "Manage customers",
  "reports.read" => "View reports",
  "settings.read" => "View settings",
  "settings.manage" => "Manage settings",
  "audit_logs.read" => "View audit logs",
  "roadmap.read" => "View the sprint roadmap",
  "roadmap.manage" => "Edit sprints and their features on the roadmap"
}.freeze

PERMISSIONS.each do |key, name|
  Permission.find_or_create_by!(key: key) { |permission| permission.name = name }
end

ROLES = {
  "super_admin" => {
    name: "Super Admin",
    description: "Full, unrestricted access to everything.",
    system: true,
    permissions: :all
  },
  "admin" => {
    name: "Admin",
    description: "Broad operational access (excludes role administration).",
    permissions: PERMISSIONS.keys - %w[roles.manage permissions.read permissions.manage users.manage settings.manage]
  },
  "inventory_manager" => {
    name: "Inventory Manager",
    description: "Manages product stock levels.",
    permissions: %w[dashboard.read products.read inventory.read inventory.manage orders.read
                    roadmap.read roadmap.manage]
  },
  "order_manager" => {
    name: "Order Manager",
    description: "Processes and fulfils orders.",
    permissions: %w[dashboard.read orders.read orders.manage customers.read payments.read
                    roadmap.read roadmap.manage]
  },
  "content_manager" => {
    name: "Content Manager",
    description: "Manages CMS content and catalog copy.",
    permissions: %w[dashboard.read cms.read cms.manage
                    products.read categories.read brands.read reviews.read
                    roadmap.read roadmap.manage]
  },
  "support" => {
    name: "Support",
    description: "Assists customers with orders and reviews.",
    permissions: %w[dashboard.read orders.read customers.read reviews.read reviews.manage
                    roadmap.read roadmap.manage]
  }
}.freeze

ROLES.each do |key, attrs|
  role = Role.find_or_create_by!(key: key) do |r|
    r.name = attrs[:name]
    r.description = attrs[:description]
    r.system = attrs.fetch(:system, false)
  end

  permissions = attrs[:permissions] == :all ? Permission.all : Permission.where(key: attrs[:permissions])
  role.permissions = permissions
end

# Bootstrap super admin (override via SEED_ADMIN_EMAIL / SEED_ADMIN_PASSWORD).
admin_email = ENV.fetch("SEED_ADMIN_EMAIL", "superadmin@aurora.test")
admin_password = ENV.fetch("SEED_ADMIN_PASSWORD", "ChangeMe123!")

super_admin = AdminUser.find_or_initialize_by(email: admin_email)
if super_admin.new_record?
  super_admin.assign_attributes(password: admin_password, first_name: "Super", last_name: "Admin")
  super_admin.save!
end
super_admin.roles = [ Role.find_by!(key: "super_admin") ] unless super_admin.roles.exists?(key: "super_admin")

# --- Site settings -----------------------------------------------------------
[
  { key: "site.name", value: "Aurora", value_type: "string", category: "general", public_read: true, description: "Store name" },
  { key: "site.tagline", value: "Premium commerce, built to scale.", value_type: "string", category: "general", public_read: true },
  { key: "site.support_email", value: "support@aurora.test", value_type: "string", category: "general", public_read: true },
  { key: "site.currency", value: "INR", value_type: "string", category: "general", public_read: true },
  { key: "checkout.min_order_value", value: 0, value_type: "number", category: "checkout", public_read: false },
  { key: "pagination.per_page_options", value: [ 10, 15, 20, 30, 50 ], value_type: "json", category: "pagination",
    public_read: false, description: "Selectable page sizes for admin lists" },
  { key: "pagination.default_per_page", value: 10, value_type: "number", category: "pagination",
    public_read: false, description: "Default page size for admin lists" }
].each do |attrs|
  SiteSetting.find_or_create_by!(key: attrs[:key]) do |setting|
    setting.assign_attributes(attrs.except(:key))
  end
end

# --- Feature flags -----------------------------------------------------------
[
  { key: "wishlist", name: "Wishlist", enabled: true },
  { key: "reviews", name: "Product Reviews", enabled: true },
  { key: "guest_checkout", name: "Guest Checkout", enabled: true },
  { key: "promo_banner", name: "Promotional Banner", enabled: false }
].each do |attrs|
  FeatureFlag.find_or_create_by!(key: attrs[:key]) do |flag|
    flag.assign_attributes(attrs.except(:key))
  end
end

# --- Catalog: tax classes, brands, categories, products ----------------------
gst5  = TaxClass.find_or_create_by!(name: "GST 5%")  { |t| t.rate = 5;  t.hsn_code = "6109" }
gst12 = TaxClass.find_or_create_by!(name: "GST 12%") { |t| t.rate = 12; t.hsn_code = "6203" }
gst18 = TaxClass.find_or_create_by!(name: "GST 18%") { |t| t.rate = 18; t.hsn_code = "8517" }

brands = {}
[
  { name: "Aurora Basics", slug: "aurora-basics" },
  { name: "Nova", slug: "nova" },
  { name: "Zenith", slug: "zenith" },
  { name: "Volt", slug: "volt" }
].each do |attrs|
  brands[attrs[:slug]] = Brand.find_or_create_by!(slug: attrs[:slug]) { |b| b.name = attrs[:name] }
end

# Extra brands (no products) so the async brand typeahead has >1 page to exercise infinite scroll.
26.times do |i|
  Brand.find_or_create_by!(slug: "label-#{format('%02d', i + 1)}") { |b| b.name = "Label #{format('%02d', i + 1)}" }
end

def upsert_category(name:, slug:, parent: nil, position: 0)
  Category.find_or_create_by!(slug: slug) do |c|
    c.name = name
    c.parent_id = parent&.id
    c.position = position
    c.visible = true
  end
end

cat = {}
cat[:men]        = upsert_category(name: "Men", slug: "men", position: 1)
cat[:topwear]    = upsert_category(name: "Topwear", slug: "topwear", parent: cat[:men], position: 1)
cat[:tshirts]    = upsert_category(name: "T-Shirts", slug: "t-shirts", parent: cat[:topwear], position: 1)
cat[:shirts]     = upsert_category(name: "Shirts", slug: "shirts", parent: cat[:topwear], position: 2)
cat[:bottomwear] = upsert_category(name: "Bottomwear", slug: "bottomwear", parent: cat[:men], position: 2)
cat[:jeans]      = upsert_category(name: "Jeans", slug: "jeans", parent: cat[:bottomwear], position: 1)
cat[:women]      = upsert_category(name: "Women", slug: "women", position: 2)
cat[:dresses]    = upsert_category(name: "Dresses", slug: "dresses", parent: cat[:women], position: 1)
cat[:electronics] = upsert_category(name: "Electronics", slug: "electronics", position: 3)
cat[:mobiles]    = upsert_category(name: "Mobiles", slug: "mobiles", parent: cat[:electronics], position: 1)
cat[:laptops]    = upsert_category(name: "Laptops", slug: "laptops", parent: cat[:electronics], position: 2)

def upsert_product(sku:, name:, category:, brand:, tax:, price:, mrp:, seed:, status: :active, flags: {})
  product = Product.find_or_create_by!(sku: sku) do |p|
    p.name = name
    p.category = category
    p.brand = brand
    p.tax_class = tax
    p.price_cents = (price * 100).to_i
    p.mrp_cents = (mrp * 100).to_i
    p.currency = "INR"
    p.status = status
    p.published_at = (status.to_sym == :active ? Time.current : nil)
    p.description = "#{name} — crafted for everyday premium quality."
    p.highlights = [ "Premium materials", "Free delivery", "Easy 7-day returns" ]
    p.featured = flags.fetch(:featured, false)
    p.new_arrival = flags.fetch(:new, false)
    p.best_seller = flags.fetch(:best, false)
  end

  if product.product_images.empty?
    product.product_images.create!(
      source_url: "https://picsum.photos/seed/#{seed}/600/800", alt_text: name, position: 0, primary: true
    )
  end
  product
end

upsert_product(sku: "TS-001", name: "Classic Cotton Tee", category: cat[:tshirts], brand: brands["aurora-basics"], tax: gst5,  price: 799,  mrp: 1299, seed: "tee1", flags: { best: true, featured: true })
upsert_product(sku: "TS-002", name: "Pima Crew Tee",       category: cat[:tshirts], brand: brands["nova"],          tax: gst5,  price: 1199, mrp: 1499, seed: "tee2", flags: { new: true })
upsert_product(sku: "SH-001", name: "Oxford Shirt",         category: cat[:shirts],  brand: brands["zenith"],        tax: gst12, price: 1899, mrp: 2499, seed: "shirt1")
upsert_product(sku: "JN-001", name: "Slim Fit Jeans",       category: cat[:jeans],   brand: brands["zenith"],        tax: gst12, price: 2499, mrp: 3499, seed: "jeans1", flags: { best: true })
upsert_product(sku: "DR-001", name: "Linen Wrap Dress",     category: cat[:dresses], brand: brands["nova"],          tax: gst12, price: 2999, mrp: 3999, seed: "dress1", flags: { featured: true, new: true })
upsert_product(sku: "MB-001", name: "Nova Phone X",         category: cat[:mobiles], brand: brands["nova"],          tax: gst18, price: 49_999, mrp: 54_999, seed: "phone1", flags: { best: true, featured: true })
upsert_product(sku: "MB-002", name: "Volt Mini",            category: cat[:mobiles], brand: brands["volt"],          tax: gst18, price: 17_999, mrp: 19_999, seed: "phone2", flags: { new: true })
upsert_product(sku: "LP-001", name: "Zenith Ultrabook 14",  category: cat[:laptops], brand: brands["zenith"],        tax: gst18, price: 89_999, mrp: 99_999, seed: "laptop1", flags: { featured: true })

# Bulk catalog — deterministic, idempotent (keyed on SKU) — to exercise
# pagination + the SearchManager filters/facets on both the storefront and admin.
leaf_catalog = [
  { category: cat[:tshirts], noun: "Tee",    tax: gst5 },
  { category: cat[:shirts],  noun: "Shirt",  tax: gst12 },
  { category: cat[:jeans],   noun: "Jeans",  tax: gst12 },
  { category: cat[:dresses], noun: "Dress",  tax: gst12 },
  { category: cat[:mobiles], noun: "Phone",  tax: gst18 },
  { category: cat[:laptops], noun: "Laptop", tax: gst18 }
]
brand_values = brands.values
adjectives = %w[Classic Premium Urban Vintage Modern Signature Everyday Luxe Essential Bold Sleek Heritage Nordic Coastal Alpine]

45.times do |i|
  spec = leaf_catalog[i % leaf_catalog.size]
  status = if (i % 9).zero? then :draft elsif (i % 13).zero? then :archived else :active end
  price = 499 + ((i * 173) % 9500)
  upsert_product(
    sku: format("CAT-%03d", i + 1),
    name: "#{adjectives[i % adjectives.size]} #{spec[:noun]} #{i + 1}",
    category: spec[:category], brand: brand_values[i % brand_values.size], tax: spec[:tax],
    price: price, mrp: price + 400 + ((i * 90) % 2500), seed: "cat#{i}", status: status,
    flags: { featured: (i % 6).zero?, new: (i % 5).zero?, best: (i % 7).zero? }
  )
end

# Bulk customers — exercise the customer list search + status filter + pagination.
customer_first_names = %w[Aarav Isha Kabir Meera Rohan Sara Vivaan Anaya Dev Priya Arjun Zara Neel Tara Om Diya Yash Kiara Aditya Nisha Reyansh Myra Ved Aisha Ishaan]
25.times do |i|
  Customer.find_or_create_by!(email: "customer#{i + 1}@aurora.test") do |c|
    c.password = "password1234"
    c.first_name = customer_first_names[i % customer_first_names.size]
    c.last_name = "Sharma"
    c.status = (i % 8).zero? ? "inactive" : "active"
    c.confirmed_at = (i % 5).zero? ? nil : Time.current
  end
end

# ---------------------------------------------------------------------------
# Sprint 5 — attributes, variants & inventory demo data (idempotent)
# ---------------------------------------------------------------------------
color_attr = ProductAttribute.find_or_create_by!(code: "color") do |a|
  a.name = "Color"
  a.filterable = true
  a.position = 1
end
size_attr = ProductAttribute.find_or_create_by!(code: "size") do |a|
  a.name = "Size"
  a.filterable = true
  a.position = 2
end
# Bottoms use a numeric waist scale, not S/M/L — modelled as its own attribute
# so tops and jeans never share a size list.
waist_attr = ProductAttribute.find_or_create_by!(code: "waist") do |a|
  a.name = "Waist (in)"
  a.filterable = true
  a.position = 3
end

seed_value = lambda do |attribute, value, position|
  attribute.attribute_values.find_or_create_by!(code: value.parameterize(separator: "_")) do |v|
    v.value = value
    v.position = position
  end
end
colors = %w[Black White Navy].each_with_index.map { |v, i| seed_value.call(color_attr, v, i) }
sizes  = %w[S M L XL].each_with_index.map  { |v, i| seed_value.call(size_attr, v, i) }
waists = %w[30 32 34 36].each_with_index.map { |v, i| seed_value.call(waist_attr, v, i) }

# Scope attributes per category so only the relevant ones appear on a product's
# variant form (and, downstream, in the storefront facets): tops/dresses use
# alpha Size, jeans use numeric Waist. Electronics fall back to all attributes.
[ cat[:tshirts], cat[:shirts], cat[:dresses] ].compact.each do |c|
  [ color_attr, size_attr ].each { |a| CategoryAttribute.find_or_create_by!(category: c, product_attribute: a) }
end
[ cat[:jeans] ].compact.each do |c|
  [ color_attr, waist_attr ].each { |a| CategoryAttribute.find_or_create_by!(category: c, product_attribute: a) }
  # Drop any stale Size scoping so jeans only ever offer Waist.
  CategoryAttribute.where(category: c, product_attribute: size_attr).delete_all
end

# Give a couple of apparel products a Color × Size variant matrix with a mixed
# stock profile (out / low / healthy) so the storefront + inventory screens have
# something real to show.
seed_matrix = lambda do |sku, base_price|
  product = Product.find_by(sku: sku)
  next if product.nil? || product.variants.non_master.exists?

  colors.first(2).each do |c|
    sizes.each_with_index do |s, idx|
      variant = product.variants.create!(price_cents: base_price * 100)
      variant.variant_option_values.create!(attribute_value: c)
      variant.variant_option_values.create!(attribute_value: s)
      variant.inventory_item.update!(low_stock_threshold: 5)
      qty = [ 0, 3, 25, 40 ][idx % 4] # out of stock, low, healthy, healthy
      Inventory::AdjustStock.new(inventory_item: variant.inventory_item, quantity: qty, reason: "restock", note: "seed").call if qty.positive?
    end
  end
end
seed_matrix.call("TS-001", 799)
seed_matrix.call("SH-001", 1899)

# Same, but Color × Waist for a pair of jeans so bottoms show a numeric waist
# facet where tops show S/M/L.
seed_waist_matrix = lambda do |sku, base_price|
  product = Product.find_by(sku: sku)
  next if product.nil? || product.variants.non_master.exists?

  colors.first(2).each do |c|
    waists.each_with_index do |w, idx|
      variant = product.variants.create!(price_cents: base_price * 100)
      variant.variant_option_values.create!(attribute_value: c)
      variant.variant_option_values.create!(attribute_value: w)
      variant.inventory_item.update!(low_stock_threshold: 5)
      qty = [ 0, 3, 25, 40 ][idx % 4]
      Inventory::AdjustStock.new(inventory_item: variant.inventory_item, quantity: qty, reason: "restock", note: "seed").call if qty.positive?
    end
  end
end
seed_waist_matrix.call("JN-001", 2499)

# Variant-option images: bind photos to colours so the PDP gallery swaps when a
# colour is selected. Demo on the Red/Blue jeans (CAT-045); one shared shot + two
# per colour. Idempotent — only (re)built if no colour-bound image exists yet.
demo = Product.find_by(sku: "CAT-045")
if demo && demo.product_images.where.not(attribute_value_id: nil).none?
  red  = AttributeValue.joins(:product_attribute).find_by(product_attributes: { code: "color" }, value: "Red")
  blue = AttributeValue.joins(:product_attribute).find_by(product_attributes: { code: "color" }, value: "Blue")
  demo.product_images.destroy_all
  [
    [ "aurora-jeans-main", nil ],
    [ "aurora-jeans-red-1", red ],  [ "aurora-jeans-red-2", red ],
    [ "aurora-jeans-blue-1", blue ], [ "aurora-jeans-blue-2", blue ]
  ].each_with_index do |(seed, value), index|
    demo.product_images.create!(
      source_url: "https://picsum.photos/seed/#{seed}/600/800",
      alt_text: [ demo.name, value&.value ].compact.join(" — "),
      position: index, primary: index.zero?, attribute_value: value
    )
  end
end

# Descriptive specifications.
seed_specs = lambda do |sku, specs|
  product = Product.find_by(sku: sku)
  next if product.nil? || product.specifications.exists?

  specs.each_with_index { |(name, value), i| product.specifications.create!(name: name, value: value, position: i) }
end
seed_specs.call("TS-001", [ [ "Material", "100% Cotton" ], [ "Fit", "Regular" ], [ "Care", "Machine wash cold" ] ])
seed_specs.call("MB-001", [ [ "Display", "6.1-inch OLED" ], [ "RAM", "8 GB" ], [ "Storage", "128 GB" ], [ "Battery", "4000 mAh" ] ])

# Stock the master variants of option-less products so the catalog isn't all
# "out of stock" (guarded so re-seeding never clobbers adjusted stock).
Product.kept.find_each do |product|
  next if product.has_variants?

  item = product.master_variant&.inventory_item
  next if item.nil? || item.on_hand.positive? || item.stock_movements.exists?

  Inventory::AdjustStock.new(inventory_item: item, quantity: 25 + (product.id % 30), reason: "restock", note: "seed").call
end

# A few related-product links for the PDP recommendation rail.
seed_relation = lambda do |from_sku, to_sku, kind|
  from = Product.find_by(sku: from_sku)
  to = Product.find_by(sku: to_sku)
  next if from.nil? || to.nil? || from == to

  ProductRelation.find_or_create_by!(product: from, related_product: to, relation_kind: kind)
end
seed_relation.call("TS-001", "TS-002", :related)
seed_relation.call("TS-001", "SH-001", :recommended)
seed_relation.call("JN-001", "TS-001", :cross_sell)

# --- CMS: banners, homepage sections, footer, static pages (idempotent) ------
Banner.find_or_create_by!(placement: "announcement", title: "Free delivery on every order — shop the new season") do |b|
  b.link_url = "/products"
end
# Hero carousel slides (multiple → the homepage hero cycles through them).
[
  { title: "New season, new essentials", subtitle: "Premium quality, thoughtfully made",
    image_url: "https://picsum.photos/seed/aurora-hero1/1600/900", link_url: "/products", cta_label: "Shop all", position: 1 },
  { title: "Tech that keeps up", subtitle: "The latest in electronics",
    image_url: "https://picsum.photos/seed/aurora-hero2/1600/900", link_url: "/c/electronics", cta_label: "Explore", position: 2 },
  { title: "Wardrobe staples, restocked", subtitle: "Best sellers back in stock",
    image_url: "https://picsum.photos/seed/aurora-hero3/1600/900", link_url: "/c/men", cta_label: "Shop men", position: 3 }
].each do |attrs|
  Banner.find_or_create_by!(placement: "hero", title: attrs[:title]) { |b| b.assign_attributes(attrs) }
end

# Promo strip banners (a row of clickable promo cards).
[
  { title: "Up to 40% off", subtitle: "Season sale", image_url: "https://picsum.photos/seed/aurora-promo1/800/500",
    link_url: "/products", cta_label: "Shop the sale", position: 1 },
  { title: "New arrivals", subtitle: "Fresh drops weekly", image_url: "https://picsum.photos/seed/aurora-promo2/800/500",
    link_url: "/products", cta_label: "Discover", position: 2 },
  { title: "Electronics", subtitle: "Gadgets & more", image_url: "https://picsum.photos/seed/aurora-promo3/800/500",
    link_url: "/c/electronics", cta_label: "Browse", position: 3 }
].each do |attrs|
  Banner.find_or_create_by!(placement: "promo", title: attrs[:title]) { |b| b.assign_attributes(attrs) }
end

# Homepage sections in order. update! so re-seeding fixes positions/config even
# for sections that already exist.
[
  { title: "Hero", section_type: "hero", position: 1, config: { "placement" => "hero" } },
  { title: "Featured deals", section_type: "promo", position: 2, config: { "placement" => "promo" } },
  { title: "Shop by category", section_type: "category_grid", position: 3, config: { "limit" => 6 } },
  { title: "New arrivals", section_type: "product_rail", position: 4, config: { "source" => "new_arrival", "limit" => 8 } },
  { title: "Best sellers", section_type: "product_rail", position: 5, config: { "source" => "best_seller", "limit" => 8 } }
].each do |attrs|
  HomepageSection.find_or_initialize_by(title: attrs[:title]).update!(attrs.merge(visible: true))
end

[
  { heading: "Shop", links: [ { "label" => "All products", "url" => "/products" }, { "label" => "Men", "url" => "/c/men" }, { "label" => "Women", "url" => "/c/women" } ] },
  { heading: "Company", links: [ { "label" => "About", "url" => "/p/about" }, { "label" => "Contact", "url" => "/p/contact" } ] },
  { heading: "Help", links: [ { "label" => "Shipping", "url" => "/p/shipping" }, { "label" => "Returns", "url" => "/p/returns" }, { "label" => "Privacy", "url" => "/p/privacy" } ] }
].each_with_index do |col, i|
  FooterSection.find_or_create_by!(heading: col[:heading]) { |f| f.links = col[:links]; f.position = i }
end

[
  { title: "About", body: "<p>Aurora is a premium commerce experience, built to scale.</p>" },
  { title: "Contact", body: "<p>Questions? Email <a href='mailto:support@aurora.test'>support@aurora.test</a>.</p>" },
  { title: "Privacy Policy", slug: "privacy", body: "<p>We respect your privacy. This is placeholder policy content.</p>" },
  { title: "Terms", body: "<p>Placeholder terms of service.</p>" },
  { title: "Shipping", body: "<p>Free delivery on every order. Placeholder shipping details.</p>" },
  { title: "Returns", body: "<p>Easy 7-day returns. Placeholder returns policy.</p>" }
].each do |page|
  StaticPage.find_or_create_by!(slug: page[:slug] || page[:title].parameterize) do |sp|
    sp.title = page[:title]
    sp.body = page[:body]
    sp.published = true
  end
end

# --- Checkout: shipping methods (idempotent) ----------------------------------
[
  { name: "Standard", description: "Delivered in 5-7 business days", price_cents: 0, position: 1 },
  { name: "Express", description: "Delivered in 1-2 business days", price_cents: 9900, position: 2 }
].each do |attrs|
  ShippingMethod.find_or_create_by!(name: attrs[:name]) do |method|
    method.description = attrs[:description]
    method.price_cents = attrs[:price_cents]
    method.position = attrs[:position]
  end
end

# --- Roadmap: sprint history (backfills the admin Roadmap tracker with the
# delivery record that used to live only in PROJECT_STATE.md) ----------------
SPRINTS = [
  { number: 1, title: "Foundation & Infrastructure", status: "completed",
    goal: "Docker Compose stack, health checks, CI, and the base Rails + Next.js skeleton.",
    estimate: "3 days",
    features: [
      { area: :backend, title: "Health/readiness endpoints",
        description: "<p>The app can report whether it's up and whether its dependencies (like the cache) are reachable.</p>",
        technical_description: "<p><code>/api/v1/health</code> (200) and <code>/api/v1/ready</code> (200/503 when Redis is down), standard envelope.</p>" },
      { area: :backend, title: "Sample Sidekiq job",
        description: "<p>Background tasks can run immediately or be scheduled for later, without slowing down the page a shopper is on.</p>",
        technical_description: "<p>Enqueues and processes both immediate and scheduled/delayed jobs.</p>" },
      { area: :frontend, title: "Homepage SSR + live health pill",
        description: "<p>The homepage loads fast and shows a live status indicator confirming the backend is reachable.</p>",
        technical_description: "<p>Server-rendered homepage displays live API health via TanStack Query + CORS.</p>" },
      { area: :other, title: "Docker Compose + CI",
        description: "<p>The whole stack can be spun up with one command, and every change is automatically checked before it ships.</p>",
        technical_description: "<p>db/redis/api/sidekiq/web services; <code>.github/workflows/ci.yml</code>.</p>" }
    ] },
  { number: 2, title: "Authentication & RBAC", status: "completed",
    goal: "Customer + admin authentication with rotating JWT refresh tokens, and role-based access control.",
    dependencies: "Sprint 1", estimate: "4 days",
    features: [
      { area: :database, title: "Auth + RBAC tables",
        description: "<p>The system can tell shoppers, staff, and their permissions apart, and remembers who's allowed to do what.</p>",
        technical_description: "<p><code>customers</code>, <code>admin_users</code>, <code>roles</code>, <code>permissions</code>, <code>role_permissions</code>, <code>admin_user_roles</code>, <code>refresh_tokens</code>.</p>" },
      { area: :backend, title: "Customer auth flow",
        description: "<p>Shoppers can create an account, verify their email, sign in, stay signed in, and reset a forgotten password.</p>",
        technical_description: "<p>Register → email verify (auto-login) → login (verified-only) → refresh (rotation) → logout → <code>/me</code>; enumeration-safe forgot/reset password.</p>" },
      { area: :backend, title: "Admin auth + RBAC",
        description: "<p>Staff sign in separately from shoppers, and each staff role only sees the tools it's allowed to use.</p>",
        technical_description: "<p>Login/refresh/logout/<code>/me</code>; 30 permissions across 6 seeded roles; super-admin implicit-all; <code>authorize_permission!</code> gating.</p>" },
      { area: :frontend, title: "Auth pages + protected routes",
        description: "<p>Sign-in/sign-up/password-reset pages, and account pages that only a signed-in shopper can reach.</p>",
        technical_description: "<p>Login/register/forgot/reset/verify-email/admin-login, auth context with refresh-on-401 interceptor, edge middleware, protected <code>/account</code>.</p>" }
    ] },
  { number: 3, title: "Navigation & Site Configuration", status: "completed",
    goal: "API-driven navigation menu, site settings, and feature flags.",
    dependencies: "Sprint 1, Sprint 2", estimate: "3 days",
    features: [
      { area: :database, title: "Navigation/settings/flags tables",
        description: "<p>The site's menu, general settings, and on/off feature switches are all editable without touching code.</p>",
        technical_description: "<p>Self-referential <code>navigation_items</code> (unlimited depth, visibility + scheduling), <code>site_settings</code> (jsonb), <code>feature_flags</code>.</p>" },
      { area: :backend, title: "Redis-cached navigation tree",
        description: "<p>The menu loads instantly for every shopper, even as it grows.</p>",
        technical_description: "<p><code>Navigation::TreeBuilder</code> (single query, no N+1) + <code>Navigation::TreeCache</code>, busted on <code>after_commit</code>.</p>" },
      { area: :frontend, title: "Mega menu + mobile nav",
        description: "<p>A hover-out menu on desktop and a slide-out drawer on mobile, both driven by the same live menu data.</p>",
        technical_description: "<p>API-driven desktop hover <code>MegaMenu</code> and a recursive <code>&lt;details&gt;</code> mobile drawer.</p>" },
      { area: :admin, title: "Server-rendered admin portal",
        description: "<p>Staff get their own sign-in and dashboard, separate from the shopper-facing site.</p>",
        technical_description: "<p>Session-authenticated <code>/admin</code> login + dashboard, replacing the placeholder Next.js admin login (superseded by ADR-016 for navigation, later replaced by the Categories tree).</p>" }
    ] },
  { number: 4, title: "Catalog Core", status: "completed",
    goal: "Products, categories, brands, and tax classes with a public storefront catalog and admin CRUD.",
    dependencies: "Sprint 1", estimate: "5 days",
    features: [
      { area: :database, title: "Catalog tables",
        description: "<p>The store can hold products organised into categories and brands, each with the right tax rate applied.</p>",
        technical_description: "<p><code>brands</code>, self-referential <code>categories</code>, <code>tax_classes</code> (GST + HSN), <code>products</code> (lifecycle enum, flags, pricing, SEO), <code>product_images</code>.</p>" },
      { area: :backend, title: "Public + admin catalog APIs",
        description: "<p>Shoppers can browse and search products; staff can create, edit, and organise them.</p>",
        technical_description: "<p>Paginated/filterable <code>/products</code>, <code>/products/:slug</code>, nested <code>/categories</code>; RBAC-gated admin CRUD for products/categories/brands/tax classes.</p>" },
      { area: :frontend, title: "PLP, category pages, PDP",
        description: "<p>Browsable product listing pages, category pages with breadcrumbs, and a full product detail page.</p>",
        technical_description: "<p>Product listing, nested category pages with breadcrumbs, and a PDP with gallery, pricing, highlights, JSON-LD + SEO metadata.</p>" },
      { area: :admin, title: "Admin catalog + team management UI",
        description: "<p>Staff can manage the product catalog and the store's own team accounts from one place.</p>",
        technical_description: "<p>Full CRUD for products/categories/brands, customer + admin-user management with login-session panels, reusable UI kit (table/search/pagination/modal/uploader).</p>" }
    ] },
  { number: 5, title: "Variants, Attributes & Inventory", status: "completed",
    goal: "Product variants (option combinations), attributes, specifications, and inventory tracking.",
    dependencies: "Sprint 4", estimate: "5 days",
    features: [
      { area: :database, title: "Variant + inventory tables",
        description: "<p>Products can come in different colours/sizes, and the store always knows exactly how many of each are in stock.</p>",
        technical_description: "<p>8 tables: attributes/values, variants/option-values, specifications, <code>inventory_items</code>, immutable <code>stock_movements</code>, product relations. Master-variant pattern for option-less products.</p>" },
      { area: :backend, title: "Inventory services",
        description: "<p>Stock levels update safely and consistently, even with many purchases happening at once.</p>",
        technical_description: "<p><code>Inventory::AdjustStock</code> (ledgered) and <code>Reserve</code>/<code>Release</code> (reservation foundation, oversell guard).</p>" },
      { area: :admin, title: "Attributes, Variants, Inventory screens",
        description: "<p>Staff can define colour/size options, manage stock per variant, and see low-stock warnings.</p>",
        technical_description: "<p>Nested value editor, per-product variant management, dedicated inventory screen with low-stock filter and adjustment history.</p>" },
      { area: :frontend, title: "Variant selector on PDP",
        description: "<p>Shoppers pick a colour/size on the product page and see the price and stock update instantly.</p>",
        technical_description: "<p>Client-side option buttons resolve the matching variant with live price/stock; specifications table; related-products rail.</p>" }
    ] },
  { number: 6, title: "CMS & Homepage", status: "completed",
    goal: "Fully CMS-driven homepage and promotional content.",
    dependencies: "Sprint 4", estimate: "4 days",
    features: [
      { area: :database, title: "CMS tables",
        description: "<p>The homepage, promotional banners, and footer are all made of editable content blocks.</p>",
        technical_description: "<p><code>banners</code> (hero/promo/announcement), <code>homepage_sections</code> (typed block registry), <code>static_pages</code>, <code>footer_sections</code>; <code>Schedulable</code> concern.</p>" },
      { area: :backend, title: "Homepage aggregation",
        description: "<p>The homepage assembles itself from whatever content blocks are currently turned on.</p>",
        technical_description: "<p><code>Cms::Homepage</code> composes blocks per type (hero, product rail, category grid, rich text) plus the announcement and footer.</p>" },
      { area: :admin, title: "Content management screens",
        description: "<p>Marketing staff can update the homepage, banners, pages, and footer without needing a developer.</p>",
        technical_description: "<p>Banners, Homepage sections, Pages, and Footer — full CRUD under a new \"Content\" sidebar group.</p>" },
      { area: :frontend, title: "Dynamic homepage",
        description: "<p>The homepage shows a hero banner, category tiles, and product rails that staff control.</p>",
        technical_description: "<p>Real homepage composed entirely from CMS data — hero, category tiles, product rails, value props.</p>" }
    ] },
  { number: 7, title: "Search & Discovery", status: "completed",
    goal: "Faceted search, filtering, infinite scroll, and discovery features across the storefront.",
    dependencies: "Sprint 4, Sprint 5", estimate: "5 days",
    features: [
      { area: :backend, title: "Faceted filters",
        description: "<p>Shoppers can narrow down a product list by brand, size, price, and availability at the same time.</p>",
        technical_description: "<p><code>Products::Search</code> — cross-table brand/attribute/availability/price filters with facet counts.</p>" },
      { area: :frontend, title: "Infinite scroll listings",
        description: "<p>Product lists load more items automatically as a shopper scrolls, instead of paging.</p>",
        technical_description: "<p>IntersectionObserver-driven infinite scroll with id-dedupe, replacing pagination on catalog listings.</p>" },
      { area: :frontend, title: "Variant-option gallery images",
        description: "<p>Picking a colour on the product page swaps in photos of that exact colour.</p>",
        technical_description: "<p>PDP gallery swaps by selected colour option; thumbnail-swap + hover-magnify interaction.</p>" },
      { area: :frontend, title: "Recently-viewed + no-result recommendations",
        description: "<p>Shoppers see products they recently looked at, and get suggestions instead of a dead end when a search finds nothing.</p>",
        technical_description: "<p>localStorage-backed recently-viewed rail; \"Popular right now\" fallback on empty search/listing results.</p>" },
      { area: :frontend, title: "Search autocomplete + synonyms",
        description: "<p>The search box suggests matches as you type, and understands common alternate spellings (like \"tee\" for \"t-shirt\").</p>",
        technical_description: "<p>Debounced header typeahead reusing the products endpoint; query synonym expansion (tee↔t-shirt, jeans↔denim).</p>" }
    ] },
  { number: 8, title: "Cart & Wishlist", status: "completed",
    goal: "Shopping cart and wishlist functionality.",
    dependencies: "Sprint 6, Sprint 2", estimate: "4 days",
    features: [
      { area: :backend, title: "Cart merge on login",
        description: "<p>Items added to the cart before signing in are still there after signing in — nothing gets lost.</p>",
        technical_description: "<p>Guest cart (<code>X-Cart-Token</code>) folds into the customer's cart on login/email-verify, summing quantities for shared variants.</p>" },
      { area: :backend, title: "Wishlist",
        description: "<p>Signed-in shoppers can save products for later.</p>",
        technical_description: "<p><code>wishlist_items</code> + <code>Api::V1::WishlistsController</code> — signed-in customers only, no guest wishlist.</p>" },
      { area: :frontend, title: "Cart page + mini-cart",
        description: "<p>A full cart page plus a quick-access mini-cart from the header, both showing what's inside and the running total.</p>",
        technical_description: "<p><code>CartProvider</code>, <code>/cart</code> page (qty stepper, remove, subtotal), header mini-cart popover with live item-count badge.</p>" },
      { area: :frontend, title: "Wishlist heart toggle",
        description: "<p>A heart icon on every product lets shoppers save or remove it from their wishlist with one click.</p>",
        technical_description: "<p>Reusable <code>WishlistButton</code> on product cards + PDP; <code>/account/wishlist</code> page; redirects guests to login.</p>" },
      { area: :backend, title: "Pagination + infinite scroll + DOM cap",
        description: "<p>Even a very large cart or wishlist stays fast to load and scroll through.</p>",
        technical_description: "<p>Cart/wishlist items paginate server-side; totals computed from full-table aggregates; 200-row DOM cap with infinite scroll on cart/wishlist pages, 20-item cap on the mini-cart.</p>" }
    ] },
  { number: 9, title: "Checkout & Order Placement", status: "completed",
    goal: "Complete checkout flow with immutable order address snapshots.",
    dependencies: "Sprint 8, Sprint 2", estimate: "4 days",
    features: [
      { area: :database, title: "Order tables",
        description: "<p>Every placed order keeps a permanent record of exactly what was bought, at what price, and delivered where — even if the catalog changes later.</p>",
        technical_description: "<p><code>orders</code>, <code>order_items</code>, <code>order_addresses</code> (form-captured snapshot, not FK'd to an address book), <code>shipping_methods</code>.</p>" },
      { area: :backend, title: "Checkout service",
        description: "<p>Placing an order double-checks prices and stock, reserves the inventory, and empties the cart — all as one safe step.</p>",
        technical_description: "<p><code>Checkout::PlaceOrder</code> — re-validates cart lines, snapshots items + address, decrements inventory (capped, never negative), clears the cart, all transactional.</p>" },
      { area: :backend, title: "Customer orders API",
        description: "<p>Shoppers can check out and view their past orders. Checkout requires signing in first.</p>",
        technical_description: "<p><code>POST /checkout</code>, <code>GET /orders</code>, <code>GET /orders/:id</code> — customer-authenticated only, no guest checkout.</p>" },
      { area: :admin, title: "Admin orders (read-only)",
        description: "<p>Staff can look up and review any order placed on the store.</p>",
        technical_description: "<p><code>Admin::OrdersController</code> list/detail with status facet, search by order number, nested order-items table.</p>" },
      { area: :frontend, title: "Checkout flow + order history",
        description: "<p>Shoppers can enter their address, pick a shipping option, place the order, and later see it in their order history.</p>",
        technical_description: "<p><code>/checkout</code> (address + shipping + review + place order), <code>/account/orders</code> (paginated history), <code>/account/orders/[id]</code> (detail/confirmation).</p>" }
    ] }
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

Rails.logger.info("Seeded #{Permission.count} permissions, #{Role.count} roles, " \
                  "#{Category.count} categories, #{Brand.count} brands, #{Product.count} products, " \
                  "#{ProductAttribute.count} attributes, #{ProductVariant.count} variants, " \
                  "#{ShippingMethod.count} shipping methods, #{Sprint.count} sprints; super admin: #{admin_email}")
