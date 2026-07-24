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
  "navigation.read" => "View navigation menus",
  "navigation.manage" => "Manage navigation menus",
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
    permissions: %w[dashboard.read cms.read cms.manage navigation.read navigation.manage
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

# --- Navigation (header mega-menu), idempotent -------------------------------
def upsert_nav(label:, parent: nil, location: "header", **attrs)
  NavigationItem.find_or_create_by!(label: label, location: location, parent_id: parent&.id) do |item|
    attrs.each { |attr, value| item[attr] = value }
  end
end

men = upsert_nav(label: "Men", slug: "men", url: "/c/men", position: 1)
men_top = upsert_nav(label: "Topwear", slug: "topwear", url: "/c/men/topwear", parent: men, position: 1)
upsert_nav(label: "T-Shirts", slug: "t-shirts", url: "/c/men/topwear/t-shirts", parent: men_top, position: 1)
upsert_nav(label: "Shirts", slug: "shirts", url: "/c/men/topwear/shirts", parent: men_top, position: 2)
men_bottom = upsert_nav(label: "Bottomwear", slug: "bottomwear", url: "/c/men/bottomwear", parent: men, position: 2)
upsert_nav(label: "Jeans", slug: "jeans", url: "/c/men/bottomwear/jeans", parent: men_bottom, position: 1)

women = upsert_nav(label: "Women", slug: "women", url: "/c/women", position: 2)
upsert_nav(label: "Dresses", slug: "dresses", url: "/c/women/dresses", parent: women, position: 1)

electronics = upsert_nav(label: "Electronics", slug: "electronics", url: "/c/electronics", position: 3)
upsert_nav(label: "Mobiles", slug: "mobiles", url: "/c/electronics/mobiles", parent: electronics, position: 1)
upsert_nav(label: "Laptops", slug: "laptops", url: "/c/electronics/laptops", parent: electronics, position: 2)

upsert_nav(label: "Sale", slug: "sale", url: "/c/sale", position: 4)

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

Rails.logger.info("Seeded #{Permission.count} permissions, #{Role.count} roles, " \
                  "#{Category.count} categories, #{Brand.count} brands, #{Product.count} products; " \
                  "super admin: #{admin_email}")
