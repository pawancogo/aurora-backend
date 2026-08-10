# frozen_string_literal: true

Rails.application.routes.draw do
  # Rails' built-in liveness endpoint (boots-with-no-exceptions check).
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Liveness + readiness probes.
      get "health", to: "health#show"
      get "ready",  to: "health#ready"

      # Public, API-driven site configuration.
      get "settings",      to: "settings#index"
      get "feature_flags", to: "feature_flags#index"

      # CMS (public): homepage blocks, site chrome (announcement + footer), pages.
      get "homepage",   to: "homepage#show"
      get "site",       to: "site#show"
      resources :pages, only: :show # :id = slug

      # Catalog (public). :id is the slug.
      resources :products, only: %i[index show]
      resources :categories, only: %i[index show]
      resources :brands, only: %i[index show]

      # Cart (guest via X-Cart-Token header, or the signed-in customer's cart).
      get    "cart",           to: "carts#show"
      post   "cart/items",     to: "carts#add_item"
      patch  "cart/items/:id", to: "carts#update_item"
      delete "cart/items/:id", to: "carts#remove_item"

      # Wishlist (signed-in customers only).
      get    "wishlist",                    to: "wishlists#show"
      get    "wishlist/product_ids",        to: "wishlists#product_ids"
      post   "wishlist/items",              to: "wishlists#add_item"
      delete "wishlist/items/:product_id",  to: "wishlists#remove_item"

      # Checkout (signed-in customers only) + order history/detail.
      get  "shipping_methods", to: "shipping_methods#index"
      post "checkout",         to: "checkout#create"
      resources :orders, only: %i[index show]

      # Customer authentication (self-service).
      namespace :customer do
        post "auth/register",            to: "registrations#create"
        post "auth/login",               to: "sessions#create"
        post "auth/refresh",             to: "sessions#refresh"
        post "auth/logout",              to: "sessions#destroy"
        get  "auth/me",                  to: "me#show"
        post "auth/verify-email",        to: "email_verifications#create"
        post "auth/resend-verification", to: "email_verifications#resend"
        post "auth/forgot-password",     to: "passwords#create"
        post "auth/reset-password",      to: "passwords#update"
      end

      # Admin authentication + RBAC.
      namespace :admin do
        post "auth/login",   to: "sessions#create"
        post "auth/refresh", to: "sessions#refresh"
        post "auth/logout",  to: "sessions#destroy"
        get  "auth/me",      to: "me#show"

        resources :roles, only: :index
        resources :permissions, only: :index

        resources :site_settings, only: %i[index show create update destroy]
        resources :feature_flags, only: %i[index create update destroy]

        resources :products, only: %i[index show create update destroy]
        resources :categories, only: %i[index show create update destroy]
        resources :brands, only: %i[index show create update destroy]
        resources :tax_classes, only: %i[index show create update destroy]
      end
    end
  end

  # Super-admin data console (full model CRUD/inspection). Session-authenticated,
  # gated to Super Admins in config/initializers/rails_admin.rb.
  mount RailsAdmin::Engine => "/superadmin", as: "rails_admin"

  # Server-rendered admin portal (session-authenticated ERB).
  namespace :admin do
    root to: "dashboard#show"
    get    "login",     to: "sessions#new",     as: :login
    post   "login",     to: "sessions#create"
    delete "logout",    to: "sessions#destroy", as: :logout
    get    "dashboard", to: "dashboard#show"

    get   "settings",             to: "settings#index",       as: :settings
    get   "settings/permissions", to: "settings#permissions", as: :settings_permissions
    get   "settings/team",        to: "settings#team",        as: :settings_team
    get    "settings/team/new",        to: "settings#new_admin",           as: :new_settings_admin
    get    "settings/team/:id",        to: "settings#show_admin",          as: :settings_admin
    patch  "settings/team/:id/roles",  to: "settings#update_admin_roles",  as: :settings_admin_roles
    post   "settings/team",            to: "settings#create_admin",        as: :settings_create_admin
    patch  "settings/team/:id/status", to: "settings#update_admin_status", as: :settings_admin_status
    delete "settings/team/:id",        to: "settings#destroy_admin",       as: :settings_destroy_admin
    delete "settings/team/:id/sessions",           to: "settings#revoke_admin_sessions", as: :settings_admin_sessions
    delete "settings/team/:id/sessions/:token_id", to: "settings#revoke_admin_session",  as: :settings_admin_session

    scope path: "settings", as: :settings do
      resources :roles, only: %i[index new create edit update destroy]
      resources :permissions, only: %i[edit update]
    end

    # Customer management (+ login sessions)
    get    "customers",                        to: "customers#index",           as: :customers
    get    "customers/:id",                    to: "customers#show",            as: :customer
    get    "customers/:id/edit",               to: "customers#edit",            as: :edit_customer
    patch  "customers/:id",                    to: "customers#update"
    patch  "customers/:id/status",             to: "customers#update_status",   as: :customer_status
    delete "customers/:id/sessions",           to: "customers#revoke_sessions", as: :customer_sessions
    delete "customers/:id/sessions/:token_id", to: "customers#revoke_session",  as: :customer_session

    # Order management (read-only — placement/fulfillment tooling is a later sprint)
    get "orders",     to: "orders#index", as: :orders
    get "orders/:id", to: "orders#show",  as: :order

    # Typeahead options for async custom-select dropdowns.
    get "options/:resource", to: "options#index", as: :options

    # Generic media upload (Active Storage) for the reusable uploader widget.
    post "uploads", to: "uploads#create", as: :uploads

    # Catalog management (server-rendered)
    get "variants", to: "variants#index", as: :variants # global catalog list of all variants
    resources :products, only: %i[index new create edit update destroy] do
      resources :variants, only: %i[index new create edit update destroy], controller: "product_variants"
      resources :relations, only: %i[create destroy], controller: "product_relations"
    end
    resources :categories, only: %i[index new create edit update destroy]
    resources :brands,     only: %i[index new create edit update destroy]
    resources :attributes, only: %i[index new create edit update destroy], controller: "attributes"

    # Inventory operations (stock adjust, low-stock filter, movement history)
    get   "inventory",                     to: "inventory#index",           as: :inventory
    get   "inventory/:variant_id",         to: "inventory#show",            as: :inventory_item
    post  "inventory/:variant_id/adjust",  to: "inventory#adjust",          as: :adjust_inventory
    patch "inventory/:variant_id/settings", to: "inventory#update_settings", as: :inventory_settings

    # CMS / content management
    resources :banners,           only: %i[index new create edit update destroy]
    resources :homepage_sections, only: %i[index new create edit update destroy], path: "homepage-sections"
    resources :static_pages,      only: %i[index new create edit update destroy], path: "pages"
    resources :footer_sections,   only: %i[index new create edit update destroy], path: "footer"
  end

  # Backend root goes to the admin portal (which redirects to login or dashboard).
  root to: redirect("/admin")

  # Anything else unmatched returns the standard JSON 404 envelope.
  match "*unmatched", to: "errors#not_found", via: :all,
        constraints: ->(req) { !req.path.start_with?("/admin", "/superadmin") }
end
