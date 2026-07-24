# frozen_string_literal: true

# RailsAdmin — a full data console (every model, raw CRUD + export) for Super
# Admins only, mounted at /superadmin. It reuses the admin portal's cookie session
# so there's one login. The curated day-to-day workflows live in the custom /admin
# portal; this is the "see everything" back office.
RailsAdmin.config do |config|
  # This app is api_only; RailsAdmin's bundled CSS/JS are served via sprockets.
  config.asset_source = :sprockets

  config.main_app_name = [ "Aurora", "Data Console" ]

  ## This is a "see everything" back office, so show the complete record.
  # By default RailsAdmin hides blank fields and the id/timestamps on the show
  # view; turn both off so every column is visible. Edit forms still omit
  # id/timestamps since those are managed automatically.
  config.compact_show_view = false
  config.default_hidden_fields = {
    base: [ :_type ],
    show: [],
    edit: %i[id _id created_at created_on deleted_at updated_at updated_on deleted_on]
  }

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

  ## Activity log — PaperTrail versions, with whodunnit resolved to the admin.
  config.audit_with :paper_trail, "AdminUser", "PaperTrail::Version"

  config.actions do
    dashboard
    index
    new
    export
    show
    edit
    delete
    bulk_delete
    history_index   # global activity log
    history_show    # per-record history
  end

  ## Render image-URL fields as a thumbnail preview AND a clickable link in
  # list + show views (the user wants to see both the image and the URL).
  # `configure` customizes the field wherever it appears without restricting the
  # visible field set; `pretty_value` applies in read-only views (list + show).
  image_thumb = proc do
    if value.present?
      v = bindings[:view]
      thumb = v.tag.a(href: value, target: "_blank", rel: "noopener") do
        v.tag.img(
          src: value,
          style: "max-height:56px;max-width:96px;border-radius:4px;object-fit:cover;display:block;margin-bottom:4px"
        )
      end
      link = v.tag.a(value, href: value, target: "_blank", rel: "noopener", class: "img-url-link")
      v.safe_join([ thumb, link ])
    end
  end

  config.model "ProductImage" do
    configure(:source_url) { pretty_value(&image_thumb) }
  end

  config.model "Category" do
    configure(:image_url) { pretty_value(&image_thumb) }
  end

  config.model "Brand" do
    configure(:logo_url) { pretty_value(&image_thumb) }
  end
end
