# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_14_122154) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addresses", force: :cascade do |t|
    t.integer "address_type", default: 0, null: false
    t.string "city", null: false
    t.string "country", default: "IN", null: false
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.string "full_name", null: false
    t.boolean "is_default", default: false, null: false
    t.string "line1", null: false
    t.string "line2"
    t.string "phone", null: false
    t.string "postal_code", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "is_default"], name: "index_addresses_on_customer_id_and_is_default"
    t.index ["customer_id"], name: "index_addresses_on_customer_id"
  end

  create_table "admin_user_roles", force: :cascade do |t|
    t.bigint "admin_user_id", null: false
    t.datetime "created_at", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["admin_user_id", "role_id"], name: "index_admin_user_roles_on_admin_user_id_and_role_id", unique: true
    t.index ["admin_user_id"], name: "index_admin_user_roles_on_admin_user_id"
    t.index ["role_id"], name: "index_admin_user_roles_on_role_id"
  end

  create_table "admin_users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email", null: false
    t.string "first_name"
    t.datetime "last_login_at"
    t.string "last_name"
    t.string "password_digest", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_admin_users_on_deleted_at"
    t.index ["email"], name: "index_admin_users_on_email", unique: true
  end

  create_table "attribute_values", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.jsonb "metadata", default: {}, null: false
    t.integer "position", default: 0, null: false
    t.bigint "product_attribute_id", null: false
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["product_attribute_id", "code"], name: "index_attribute_values_on_product_attribute_id_and_code", unique: true
    t.index ["product_attribute_id"], name: "index_attribute_values_on_product_attribute_id"
  end

  create_table "banners", force: :cascade do |t|
    t.string "alt_text"
    t.datetime "created_at", null: false
    t.string "cta_label"
    t.datetime "ends_at"
    t.string "image_url"
    t.string "link_url"
    t.string "mobile_image_url"
    t.string "placement", default: "hero", null: false
    t.integer "position", default: 0, null: false
    t.datetime "starts_at"
    t.string "subtitle"
    t.string "title"
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["placement", "position"], name: "index_banners_on_placement_and_position"
    t.index ["visible"], name: "index_banners_on_visible"
  end

  create_table "brands", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "logo_url"
    t.string "meta_description"
    t.string "meta_title"
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_brands_on_deleted_at"
    t.index ["slug"], name: "index_brands_on_slug", unique: true
  end

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_variant_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["cart_id", "product_variant_id"], name: "index_cart_items_on_cart_id_and_product_variant_id", unique: true
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_variant_id"], name: "index_cart_items_on_product_variant_id"
  end

  create_table "carts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id"
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_carts_on_customer_id_unique", unique: true
    t.index ["token"], name: "index_carts_on_token", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.string "image_url"
    t.string "meta_description"
    t.string "meta_title"
    t.string "name", null: false
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["deleted_at"], name: "index_categories_on_deleted_at"
    t.index ["parent_id", "position"], name: "index_categories_on_parent_id_and_position"
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
    t.index ["visible"], name: "index_categories_on_visible"
  end

  create_table "category_attributes", force: :cascade do |t|
    t.bigint "category_id", null: false
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "product_attribute_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category_id", "product_attribute_id"], name: "index_category_attributes_uniqueness", unique: true
    t.index ["category_id"], name: "index_category_attributes_on_category_id"
    t.index ["product_attribute_id"], name: "index_category_attributes_on_product_attribute_id"
  end

  create_table "customers", force: :cascade do |t|
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token_digest"
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "deleted_at"
    t.string "email", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest", null: false
    t.string "phone"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token_digest"
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_token_digest"], name: "index_customers_on_confirmation_token_digest"
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
    t.index ["email"], name: "index_customers_on_email", unique: true
    t.index ["reset_password_token_digest"], name: "index_customers_on_reset_password_token_digest"
  end

  create_table "feature_flags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.boolean "enabled", default: false, null: false
    t.string "key", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_feature_flags_on_key", unique: true
  end

  create_table "footer_sections", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "heading", null: false
    t.jsonb "links", default: [], null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["position"], name: "index_footer_sections_on_position"
  end

  create_table "homepage_sections", force: :cascade do |t|
    t.jsonb "config", default: {}, null: false
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.integer "position", default: 0, null: false
    t.string "section_type", null: false
    t.datetime "starts_at"
    t.string "subtitle"
    t.string "title"
    t.datetime "updated_at", null: false
    t.boolean "visible", default: true, null: false
    t.index ["position"], name: "index_homepage_sections_on_position"
    t.index ["visible"], name: "index_homepage_sections_on_visible"
  end

  create_table "inventory_items", force: :cascade do |t|
    t.boolean "backorderable", default: false, null: false
    t.datetime "created_at", null: false
    t.integer "low_stock_threshold", default: 0, null: false
    t.integer "on_hand", default: 0, null: false
    t.bigint "product_variant_id", null: false
    t.integer "reserved", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["product_variant_id"], name: "index_inventory_items_on_product_variant_id", unique: true
  end

  create_table "order_addresses", force: :cascade do |t|
    t.integer "address_type", default: 0, null: false
    t.string "city", null: false
    t.string "country", default: "IN", null: false
    t.datetime "created_at", null: false
    t.string "full_name", null: false
    t.string "line1", null: false
    t.string "line2"
    t.bigint "order_id", null: false
    t.string "phone", null: false
    t.string "postal_code", null: false
    t.string "state", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_addresses_on_order_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "line_total_cents", null: false
    t.jsonb "options_snapshot", default: [], null: false
    t.bigint "order_id", null: false
    t.string "product_name", null: false
    t.bigint "product_variant_id"
    t.integer "quantity", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.string "variant_sku", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_variant_id"], name: "index_order_items_on_product_variant_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "cancelled_at"
    t.datetime "created_at", null: false
    t.string "currency", default: "INR", null: false
    t.bigint "customer_id", null: false
    t.string "order_number", null: false
    t.datetime "placed_at", null: false
    t.integer "shipping_cents", default: 0, null: false
    t.bigint "shipping_method_id"
    t.string "shipping_method_name", null: false
    t.integer "status", default: 0, null: false
    t.integer "subtotal_cents", null: false
    t.integer "total_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["shipping_method_id"], name: "index_orders_on_shipping_method_id"
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "INR", null: false
    t.bigint "order_id", null: false
    t.jsonb "raw_payload"
    t.string "razorpay_order_id", null: false
    t.string "razorpay_payment_id"
    t.string "razorpay_refund_id"
    t.string "razorpay_signature"
    t.datetime "refunded_at"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_payments_on_order_id"
    t.index ["razorpay_order_id"], name: "index_payments_on_razorpay_order_id", unique: true
    t.index ["razorpay_payment_id"], name: "index_payments_on_razorpay_payment_id", unique: true
  end

  create_table "permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "key", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_permissions_on_key", unique: true
  end

  create_table "product_attributes", force: :cascade do |t|
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.boolean "filterable", default: false, null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.boolean "searchable", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_product_attributes_on_code", unique: true
  end

  create_table "product_images", force: :cascade do |t|
    t.string "alt_text"
    t.bigint "attribute_value_id"
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.boolean "primary", default: false, null: false
    t.bigint "product_id", null: false
    t.string "source_url", null: false
    t.datetime "updated_at", null: false
    t.index ["attribute_value_id"], name: "index_product_images_on_attribute_value_id"
    t.index ["product_id", "position"], name: "index_product_images_on_product_id_and_position"
    t.index ["product_id"], name: "index_product_images_on_product_id"
  end

  create_table "product_relations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "product_id", null: false
    t.bigint "related_product_id", null: false
    t.integer "relation_kind", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "related_product_id", "relation_kind"], name: "index_product_relations_uniqueness", unique: true
    t.index ["product_id"], name: "index_product_relations_on_product_id"
    t.index ["related_product_id"], name: "index_product_relations_on_related_product_id"
  end

  create_table "product_specifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.bigint "product_id", null: false
    t.string "spec_group"
    t.datetime "updated_at", null: false
    t.string "value", null: false
    t.index ["product_id"], name: "index_product_specifications_on_product_id"
  end

  create_table "product_variants", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "barcode"
    t.datetime "created_at", null: false
    t.string "image_url"
    t.boolean "is_master", default: false, null: false
    t.integer "mrp_cents"
    t.string "name"
    t.integer "position", default: 0, null: false
    t.integer "price_cents"
    t.bigint "product_id", null: false
    t.string "sku", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "is_master"], name: "index_product_variants_on_product_id_and_is_master"
    t.index ["product_id"], name: "index_product_variants_on_product_id"
    t.index ["sku"], name: "index_product_variants_on_sku", unique: true
  end

  create_table "products", force: :cascade do |t|
    t.boolean "best_seller", default: false, null: false
    t.bigint "brand_id"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.string "currency", default: "INR", null: false
    t.datetime "deleted_at"
    t.text "description"
    t.jsonb "dimensions", default: {}, null: false
    t.boolean "featured", default: false, null: false
    t.jsonb "highlights", default: [], null: false
    t.string "meta_description"
    t.string "meta_title"
    t.integer "mrp_cents", default: 0, null: false
    t.string "name", null: false
    t.boolean "new_arrival", default: false, null: false
    t.integer "price_cents", default: 0, null: false
    t.datetime "published_at"
    t.string "search_keywords"
    t.string "sku", null: false
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.bigint "tax_class_id"
    t.datetime "updated_at", null: false
    t.string "warranty"
    t.integer "weight_grams"
    t.index ["best_seller"], name: "index_products_on_best_seller"
    t.index ["brand_id"], name: "index_products_on_brand_id"
    t.index ["category_id"], name: "index_products_on_category_id"
    t.index ["deleted_at"], name: "index_products_on_deleted_at"
    t.index ["featured"], name: "index_products_on_featured"
    t.index ["new_arrival"], name: "index_products_on_new_arrival"
    t.index ["published_at"], name: "index_products_on_published_at"
    t.index ["sku"], name: "index_products_on_sku", unique: true
    t.index ["slug"], name: "index_products_on_slug", unique: true
    t.index ["status"], name: "index_products_on_status"
    t.index ["tax_class_id"], name: "index_products_on_tax_class_id"
  end

  create_table "refresh_tokens", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "ip_address"
    t.bigint "owner_id", null: false
    t.string "owner_type", null: false
    t.datetime "revoked_at"
    t.string "token_digest", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.index ["expires_at"], name: "index_refresh_tokens_on_expires_at"
    t.index ["owner_type", "owner_id"], name: "index_refresh_tokens_on_owner_type_and_owner_id"
    t.index ["token_digest"], name: "index_refresh_tokens_on_token_digest", unique: true
  end

  create_table "role_permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "permission_id", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["permission_id"], name: "index_role_permissions_on_permission_id"
    t.index ["role_id", "permission_id"], name: "index_role_permissions_on_role_id_and_permission_id", unique: true
    t.index ["role_id"], name: "index_role_permissions_on_role_id"
  end

  create_table "roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "key", null: false
    t.string "name", null: false
    t.boolean "system", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_roles_on_key", unique: true
  end

  create_table "shipping_methods", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "price_cents", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "site_settings", force: :cascade do |t|
    t.string "category", default: "general", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.string "key", null: false
    t.boolean "public_read", default: false, null: false
    t.datetime "updated_at", null: false
    t.jsonb "value", default: {}, null: false
    t.string "value_type", default: "string", null: false
    t.index ["category"], name: "index_site_settings_on_category"
    t.index ["key"], name: "index_site_settings_on_key", unique: true
  end

  create_table "sprint_features", force: :cascade do |t|
    t.integer "area", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "position", default: 0, null: false
    t.bigint "sprint_id", null: false
    t.text "technical_description"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["sprint_id"], name: "index_sprint_features_on_sprint_id"
  end

  create_table "sprints", force: :cascade do |t|
    t.date "completed_on"
    t.datetime "created_at", null: false
    t.string "dependencies"
    t.string "estimate"
    t.text "goal"
    t.integer "number", null: false
    t.date "started_on"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["number"], name: "index_sprints_on_number", unique: true
  end

  create_table "static_pages", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "meta_description"
    t.string "meta_title"
    t.integer "position", default: 0, null: false
    t.boolean "published", default: false, null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_static_pages_on_slug", unique: true
  end

  create_table "stock_movements", force: :cascade do |t|
    t.bigint "admin_user_id"
    t.datetime "created_at", null: false
    t.bigint "inventory_item_id", null: false
    t.string "note"
    t.integer "quantity", null: false
    t.integer "reason", default: 0, null: false
    t.index ["admin_user_id"], name: "index_stock_movements_on_admin_user_id"
    t.index ["inventory_item_id", "created_at"], name: "index_stock_movements_on_inventory_item_id_and_created_at"
    t.index ["inventory_item_id"], name: "index_stock_movements_on_inventory_item_id"
  end

  create_table "tax_classes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hsn_code"
    t.string "name", null: false
    t.decimal "rate", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tax_classes_on_name", unique: true
  end

  create_table "variant_option_values", force: :cascade do |t|
    t.bigint "attribute_value_id", null: false
    t.datetime "created_at", null: false
    t.bigint "product_variant_id", null: false
    t.datetime "updated_at", null: false
    t.index ["attribute_value_id"], name: "index_variant_option_values_on_attribute_value_id"
    t.index ["product_variant_id", "attribute_value_id"], name: "index_variant_option_values_uniqueness", unique: true
    t.index ["product_variant_id"], name: "index_variant_option_values_on_product_variant_id"
  end

  create_table "versions", force: :cascade do |t|
    t.datetime "created_at"
    t.string "event", null: false
    t.bigint "item_id", null: false
    t.string "item_type", null: false
    t.jsonb "object"
    t.jsonb "object_changes"
    t.string "whodunnit"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "wishlist_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "customer_id", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id", "product_id"], name: "index_wishlist_items_on_customer_id_and_product_id", unique: true
    t.index ["customer_id"], name: "index_wishlist_items_on_customer_id"
    t.index ["product_id"], name: "index_wishlist_items_on_product_id"
  end

  add_foreign_key "addresses", "customers"
  add_foreign_key "admin_user_roles", "admin_users"
  add_foreign_key "admin_user_roles", "roles"
  add_foreign_key "attribute_values", "product_attributes"
  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "product_variants"
  add_foreign_key "carts", "customers"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "category_attributes", "categories"
  add_foreign_key "category_attributes", "product_attributes"
  add_foreign_key "inventory_items", "product_variants"
  add_foreign_key "order_addresses", "orders"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "product_variants"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "shipping_methods"
  add_foreign_key "payments", "orders"
  add_foreign_key "product_images", "attribute_values"
  add_foreign_key "product_images", "products"
  add_foreign_key "product_relations", "products"
  add_foreign_key "product_relations", "products", column: "related_product_id"
  add_foreign_key "product_specifications", "products"
  add_foreign_key "product_variants", "products"
  add_foreign_key "products", "brands"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "tax_classes"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "sprint_features", "sprints"
  add_foreign_key "stock_movements", "admin_users", on_delete: :nullify
  add_foreign_key "stock_movements", "inventory_items"
  add_foreign_key "variant_option_values", "attribute_values"
  add_foreign_key "variant_option_values", "product_variants"
  add_foreign_key "wishlist_items", "customers"
  add_foreign_key "wishlist_items", "products"
end
