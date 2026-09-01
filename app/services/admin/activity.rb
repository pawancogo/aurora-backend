# frozen_string_literal: true

module Admin
  # Turns a PaperTrail version into a one-line activity row for the ops feed.
  class Activity
    Item = Data.define(:id, :time, :actor, :verb, :item_type, :item_label, :path)

    VERBS = { "create" => "created", "update" => "updated", "destroy" => "deleted" }.freeze
    PAGE_SIZE = 40

    def self.recent(limit: 10)
      versions = PaperTrail::Version.order(created_at: :desc, id: :desc).limit(limit).to_a
      wrap_all(versions)
    end

    def self.paginate(params)
      versions = PaperTrail::Version.order(created_at: :desc, id: :desc).page(params[:page]).per(PAGE_SIZE)
      [ wrap_all(versions), versions ]
    end

    def self.wrap(version, admins = {})
      admin = admins[version.whodunnit.to_s]
      Item.new(
        id: version.id,
        time: version.created_at,
        actor: admin&.full_name.presence || admin&.email || (version.whodunnit.present? ? "Admin ##{version.whodunnit}" : "System"),
        verb: VERBS.fetch(version.event, version.event),
        item_type: version.item_type.to_s.underscore.humanize,
        item_label: label_for(version),
        path: path_for(version)
      )
    end

    def self.wrap_all(versions)
      admins = AdminUser.where(id: versions.map(&:whodunnit).compact).index_by { |admin| admin.id.to_s }
      versions.map { |version| wrap(version, admins) }
    end
    private_class_method :wrap_all

    def self.label_for(version)
      record = version.item
      return fallback_label(version) if record.nil?

      record.try(:name).presence ||
        record.try(:order_number).presence ||
        record.try(:rma_number).presence ||
        record.try(:email).presence ||
        record.try(:title).presence ||
        record.try(:sku).presence ||
        record.try(:body).to_s.truncate(60).presence ||
        "##{version.item_id}"
    end

    def self.fallback_label(version)
      snapshot = version.object
      snapshot = {} unless snapshot.is_a?(Hash)
      snapshot["name"] || snapshot["order_number"] || snapshot["email"] ||
        snapshot["sku"] || snapshot["title"] || "##{version.item_id}"
    end

    def self.path_for(version)
      id = version.item_id
      snapshot = version.object.is_a?(Hash) ? version.object : {}
      case version.item_type
      when "Product" then "/admin/products/#{id}/edit"
      when "Order" then "/admin/orders/#{id}"
      when "Customer" then "/admin/customers/#{id}"
      when "ReturnRequest" then "/admin/returns/#{id}"
      when "Review" then "/admin/reviews/#{id}"
      when "ProductQuestion" then "/admin/questions/#{id}"
      when "InventoryItem"
        variant_id = version.item&.product_variant_id || snapshot["product_variant_id"]
        variant_id && "/admin/inventory/#{variant_id}"
      when "Banner" then "/admin/banners/#{id}/edit"
      when "StaticPage" then "/admin/pages/#{id}/edit"
      when "Category" then "/admin/categories/#{id}/edit"
      when "Brand" then "/admin/brands/#{id}/edit"
      when "AdminUser" then "/admin/settings/team/#{id}"
      end
    end
    private_class_method :label_for, :fallback_label, :path_for
  end
end
