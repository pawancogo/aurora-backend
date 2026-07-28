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
  "audit_logs.read" => "View audit logs"
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
    permissions: %w[dashboard.read products.read inventory.read inventory.manage orders.read]
  },
  "order_manager" => {
    name: "Order Manager",
    description: "Processes and fulfils orders.",
    permissions: %w[dashboard.read orders.read orders.manage customers.read payments.read]
  },
  "content_manager" => {
    name: "Content Manager",
    description: "Manages CMS content and catalog copy.",
    permissions: %w[dashboard.read cms.read cms.manage
                    products.read categories.read brands.read reviews.read]
  },
  "support" => {
    name: "Support",
    description: "Assists customers with orders and reviews.",
    permissions: %w[dashboard.read orders.read customers.read reviews.read reviews.manage]
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

Rails.logger.info("Seeded #{Permission.count} permissions, #{Role.count} roles, " \
                  "#{Category.count} categories, #{Brand.count} brands, #{Product.count} products, " \
                  "#{ProductAttribute.count} attributes, #{ProductVariant.count} variants; " \
                  "super admin: #{admin_email}")
