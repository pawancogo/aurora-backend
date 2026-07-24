source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.1.3"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use Redis adapter to run Action Cable in production
# gem "redis", ">= 4.0.1"

# Password hashing via has_secure_password
gem "bcrypt", "~> 3.1"

# JSON Web Tokens for API authentication
gem "jwt", "~> 2.9"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

# Cross-Origin Resource Sharing for the storefront frontend
gem "rack-cors"

# Redis client (readiness checks, caching, Sidekiq backend)
gem "redis", "~> 5.3"

# Background job processing
gem "sidekiq", "~> 8.0"

# Pin connection_pool to 2.x: 3.0 changed TimedStack#pop and breaks Sidekiq 7.3's
# scheduler/retry poller. Also backs our REDIS_POOL (readiness checks, caching).
gem "connection_pool", "~> 2.5"

# Request throttling / rate limiting
gem "rack-attack"

# Pagination
gem "kaminari"

# Activity/audit trail — records every change with who performed it (whodunnit).
gem "paper_trail"

# Super-admin data console — full model CRUD/inspection, mounted at /superadmin.
# sprockets-rails serves RailsAdmin's bundled CSS/JS (this app is otherwise api_only).
gem "rails_admin", "~> 3.0"
gem "sprockets-rails"
gem "sassc-rails" # compiles RailsAdmin's SCSS under sprockets

# File/media uploads — one GenericUploader, provider chosen via STORAGE_PROVIDER.
gem "carrierwave", "~> 3.0"
# Optional storage providers — required lazily only when selected (config/initializers/carrierwave.rb),
# so they add no boot cost for the default local provider but need no code change to switch on.
gem "fog-aws", require: false    # AWS S3 (production)
gem "cloudinary", require: false # Cloudinary (media-heavy: images/video)

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Testing
  gem "rspec-rails", "~> 7.1"
  gem "factory_bot_rails"

  # Load .env files in development and test
  gem "dotenv-rails"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false
end
