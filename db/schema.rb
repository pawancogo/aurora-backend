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

ActiveRecord::Schema[8.1].define(version: 2026_07_23_100005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

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

  create_table "navigation_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.string "icon"
    t.string "image_url"
    t.string "label", null: false
    t.string "link_type", default: "internal", null: false
    t.string "location", default: "header", null: false
    t.string "meta_description"
    t.string "meta_title"
    t.boolean "open_in_new_tab", default: false, null: false
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.string "slug"
    t.datetime "starts_at"
    t.datetime "updated_at", null: false
    t.string "url"
    t.boolean "visible", default: true, null: false
    t.index ["location", "parent_id", "position"], name: "index_navigation_items_on_location_and_parent_id_and_position"
    t.index ["parent_id"], name: "index_navigation_items_on_parent_id"
    t.index ["visible"], name: "index_navigation_items_on_visible"
  end

  create_table "permissions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "key", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_permissions_on_key", unique: true
  end

  create_table "product_images", force: :cascade do |t|
    t.string "alt_text"
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.boolean "primary", default: false, null: false
    t.bigint "product_id", null: false
    t.string "source_url", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "position"], name: "index_product_images_on_product_id_and_position"
    t.index ["product_id"], name: "index_product_images_on_product_id"
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

  create_table "tax_classes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hsn_code"
    t.string "name", null: false
    t.decimal "rate", precision: 5, scale: 2, default: "0.0", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tax_classes_on_name", unique: true
  end

  add_foreign_key "admin_user_roles", "admin_users"
  add_foreign_key "admin_user_roles", "roles"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "navigation_items", "navigation_items", column: "parent_id"
  add_foreign_key "product_images", "products"
  add_foreign_key "products", "brands"
  add_foreign_key "products", "categories"
  add_foreign_key "products", "tax_classes"
  add_foreign_key "role_permissions", "permissions"
  add_foreign_key "role_permissions", "roles"
end
