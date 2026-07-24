# frozen_string_literal: true

# Allow the Next.js storefront to call the API from the browser.
# Origins are environment-driven (comma-separated) so staging/prod can differ.
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*ENV.fetch("FRONTEND_ORIGIN", "http://localhost:3000").split(","))

    resource "/api/*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             expose: %w[Authorization],
             credentials: false,
             max_age: 600
  end
end
