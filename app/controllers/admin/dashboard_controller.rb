# frozen_string_literal: true

module Admin
  class DashboardController < BaseController
    # GET /admin (root) and /admin/dashboard
    def show
      metrics = Metrics.new
      @cards = metrics.cards.select { |card| allowed_to?(card.permission) }
      @queues = metrics.queues.select { |queue| allowed_to?(queue.permission) }
      @activity = Activity.recent(limit: 10)
    end
  end
end
