# frozen_string_literal: true

# RailsAdmin — a full data console (every model, raw CRUD + export) for Super
# Admins only, mounted at /superadmin. It reuses the admin portal's cookie session
# so there's one login. The curated day-to-day workflows live in the custom /admin
# portal; this is the "see everything" back office.
RailsAdmin.config do |config|
  # This app is api_only; RailsAdmin's bundled CSS/JS are served via sprockets.
  config.asset_source = :sprockets

  config.main_app_name = [ "Aurora", "Data Console" ]

  ## Authentication — require a signed-in, active admin (same session as /admin).
  config.authenticate_with do
    admin = (AdminUser.kept.find_by(id: session[:admin_user_id]) if session[:admin_user_id])
    redirect_to(main_app.admin_login_path, alert: "Please sign in to continue.") unless admin&.active_for_auth?
  end

  config.current_user_method do
    AdminUser.kept.find_by(id: session[:admin_user_id]) if session[:admin_user_id]
  end

  ## Authorization — Super Admins only; everyone else bounced to the portal.
  config.authorize_with do
    unless _current_user&.super_admin?
      redirect_to main_app.admin_root_path, alert: "The data console is restricted to Super Admins."
    end
  end

  config.actions do
    dashboard
    index
    new
    export
    show
    edit
    delete
    bulk_delete
  end
end
