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
      resources :products, only: %i[index show] do
        resources :reviews, only: %i[index create], controller: "product_reviews"
        resources :questions, only: %i[index create], controller: "product_questions"
      end
      post "reviews/:id/vote", to: "review_votes#create"
      post "questions/:question_id/answers", to: "product_answers#create"
      get "account/reviews", to: "account_reviews#index"
      get "account/reviews/pending", to: "account_reviews#pending"
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
      get  "shipping_methods",                   to: "shipping_methods#index"
      post "checkout",                           to: "checkout#create"
      post "checkout/:order_id/verify_payment",  to: "checkout#verify_payment"
      resources :orders, only: %i[index show] do
        post :cancel, on: :member
        resources :return_requests, only: :create
      end
      resources :return_requests, only: %i[index show]

      # In-app inbox + delivery preferences. Unsubscribe is public (token in query/body).
      resources :notifications, only: :index do
        get :unread_count, on: :collection
        post :read_all, on: :collection
        patch :read, on: :member
      end
      resource :notification_preferences, only: %i[show update]
      get  "unsubscribe", to: "unsubscribes#show"
      post "unsubscribe", to: "unsubscribes#create"

      # Razorpay webhook (signature-verified, no customer/admin auth).
      post "webhooks/razorpay", to: "webhooks#razorpay"

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

        resources :addresses, only: %i[index create update destroy] do
          patch :default, on: :member
        end
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
    get    "activity",  to: "activity#index", as: :activity

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
    get    "customers/export",                 to: "customers#export",          as: :export_customers
    get    "customers",                        to: "customers#index",           as: :customers
    get    "customers/:id",                    to: "customers#show",            as: :customer
    get    "customers/:id/edit",               to: "customers#edit",            as: :edit_customer
    patch  "customers/:id",                    to: "customers#update"
    patch  "customers/:id/status",             to: "customers#update_status",   as: :customer_status
    post   "customers/:id/notes",              to: "customers#create_note",     as: :customer_notes
    delete "customers/:id/sessions",           to: "customers#revoke_sessions", as: :customer_sessions
    delete "customers/:id/sessions/:token_id", to: "customers#revoke_session",  as: :customer_session

    # Payment settings (Razorpay payment-methods config).
    get   "payment_settings", to: "payment_settings#show",   as: :payment_settings
    patch "payment_settings", to: "payment_settings#update"

    # Order management + fulfillment actions (advance one step, cancel/reject, refund).
    get   "orders/export",      to: "orders#export",  as: :export_orders
    get   "orders",             to: "orders#index",   as: :orders
    get   "orders/:id",         to: "orders#show",    as: :order
    patch "orders/:id/advance", to: "orders#advance", as: :advance_order
    patch "orders/:id/cancel",  to: "orders#cancel",  as: :cancel_order
    patch "orders/:id/refund",  to: "orders#refund",  as: :refund_order
    patch "orders/:id/shipment", to: "orders#update_shipment", as: :order_shipment
    post  "orders/:id/shipment_events", to: "orders#create_shipment_event", as: :order_shipment_events

    get   "returns",              to: "return_requests#index",    as: :returns
    get   "returns/:id",          to: "return_requests#show",     as: :return_request
    patch "returns/:id/approve",  to: "return_requests#approve",  as: :approve_return
    patch "returns/:id/reject",   to: "return_requests#reject",   as: :reject_return
    patch "returns/:id/receive",  to: "return_requests#receive",  as: :receive_return
    patch "returns/:id/complete", to: "return_requests#complete", as: :complete_return

    get   "reviews",              to: "reviews#index",   as: :reviews
    get   "reviews/:id",          to: "reviews#show",    as: :review
    patch "reviews/:id/publish",  to: "reviews#publish", as: :publish_review
    patch "reviews/:id/hide",     to: "reviews#hide",    as: :hide_review
    patch "reviews/:id/respond",  to: "reviews#respond", as: :respond_review

    get   "questions",                    to: "questions#index",  as: :questions
    get   "questions/:id",                to: "questions#show",   as: :question
    patch "questions/:id/publish",        to: "questions#publish", as: :publish_question
    patch "questions/:id/hide",           to: "questions#hide",    as: :hide_question
    post  "questions/:id/answers",        to: "questions#answer",  as: :answer_question
    patch "answers/:id/publish",          to: "answers#publish",   as: :publish_answer
    patch "answers/:id/hide",             to: "answers#hide",      as: :hide_answer

    # Typeahead options for async custom-select dropdowns.
    get "options/:resource", to: "options#index", as: :options

    # Generic media upload (Active Storage) for the reusable uploader widget.
    post "uploads", to: "uploads#create", as: :uploads

    # Catalog management (server-rendered)
    get "variants", to: "variants#index", as: :variants # global catalog list of all variants
    resources :products, only: %i[index new create edit update destroy] do
      collection do
        get :export
        get :import, action: :new_import
        post :import
      end
      resources :variants, only: %i[index new create edit update destroy], controller: "product_variants"
      resources :relations, only: %i[create destroy], controller: "product_relations"
    end
    resources :categories, only: %i[index new create edit update destroy]
    resources :brands,     only: %i[index new create edit update destroy]
    resources :attributes, only: %i[index new create edit update destroy], controller: "attributes"

    # Inventory operations (stock adjust, low-stock filter, movement history)
    get   "inventory/export",              to: "inventory#export",          as: :export_inventory
    get   "inventory",                     to: "inventory#index",           as: :inventory
    get   "inventory/:variant_id",         to: "inventory#show",            as: :inventory_item
    post  "inventory/:variant_id/adjust",  to: "inventory#adjust",          as: :adjust_inventory
    patch "inventory/:variant_id/settings", to: "inventory#update_settings", as: :inventory_settings

    # CMS / content management
    resources :banners,           only: %i[index new create edit update destroy]
    resources :homepage_sections, only: %i[index new create edit update destroy], path: "homepage-sections"
    resources :static_pages,      only: %i[index new create edit update destroy], path: "pages"
    resources :footer_sections,   only: %i[index new create edit update destroy], path: "footer"

    # Roadmap: sprint-wise feature tracker (viewable/editable by every admin role).
    resources :sprints, only: %i[index show new create edit update destroy] do
      resources :features, only: %i[new create edit update destroy], controller: "sprint_features"
    end
  end

  # Backend root goes to the admin portal (which redirects to login or dashboard).
  root to: redirect("/admin")

  # Anything else unmatched returns the standard JSON 404 envelope.
  match "*unmatched", to: "errors#not_found", via: :all,
        constraints: ->(req) { !req.path.start_with?("/admin", "/superadmin") }
end
