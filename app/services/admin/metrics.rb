# frozen_string_literal: true

module Admin
  # Live ops numbers for the admin home screen.
  class Metrics
    include Rails.application.routes.url_helpers

    Card = Data.define(:label, :value, :path, :permission)
    Queue = Data.define(:label, :count, :path, :permission)

    def cards
      [
        Card.new("Orders today", Order.where(placed_at: Time.current.all_day).count, admin_orders_path, "orders.read"),
        Card.new("Revenue (7d)", rupees(week_revenue_cents), admin_orders_path, "orders.read"),
        Card.new("Open fulfillment", fulfillment_scope.count, admin_orders_path(fulfillment: 1), "orders.read"),
        Card.new("Refunds pending", Payment.refund_pending.count, admin_orders_path(refund_pending: 1), "orders.read"),
        Card.new("Open returns", ReturnRequest.open.count, admin_returns_path, "orders.read"),
        Card.new("Reviews to moderate", Review.pending.count, admin_reviews_path(status: "pending"), "reviews.read"),
        Card.new("Low stock", low_stock_count, admin_inventory_path(low_stock: 1), "inventory.read"),
        Card.new("New customers (7d)", Customer.kept.where(created_at: 7.days.ago..).count, admin_customers_path, "customers.read")
      ]
    end

    def queues
      [
        Queue.new("Needs fulfillment", fulfillment_scope.count, admin_orders_path(fulfillment: 1), "orders.read"),
        Queue.new("Refund pending", Payment.refund_pending.count, admin_orders_path(refund_pending: 1), "orders.read"),
        Queue.new("Open returns", ReturnRequest.open.count, admin_returns_path, "orders.read"),
        Queue.new("Pending reviews", Review.pending.count, admin_reviews_path(status: "pending"), "reviews.read"),
        Queue.new("Low stock", low_stock_count, admin_inventory_path(low_stock: 1), "inventory.read")
      ]
    end

    private

    def fulfillment_scope
      Order.where(status: %w[confirmed accepted ready_to_ship])
    end

    def low_stock_count
      ProductVariant.purchasable
                    .joins(:product, :inventory_item)
                    .where(products: { deleted_at: nil })
                    .merge(InventoryItem.low_stock)
                    .count
    end

    def week_revenue_cents
      Payment.captured.where(updated_at: 7.days.ago..).sum(:amount_cents)
    end

    def rupees(cents)
      "₹#{format('%.2f', cents.to_i / 100.0)}"
    end
  end
end
